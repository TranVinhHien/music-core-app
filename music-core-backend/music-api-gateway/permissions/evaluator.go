package permissions

import (
	"encoding/json"
	"fmt"
	"os"
	"path"
	"strings"
	"sync"
)

// RolePermission defines the allowed HTTP methods and path patterns for a specific role.
type RolePermission struct {
	Role        string              `json:"role"`
	Permissions map[string][]string `json:"permissions"`
}

// PermissionsFile represents the schema of permissions.json (roles-only, public routes configured in gateway.yaml).
type PermissionsFile struct {
	Roles []RolePermission `json:"roles"`
}

// Evaluator evaluates route access for user roles based on permissions.json.
type Evaluator struct {
	mu       sync.RWMutex
	rolesMap map[string]map[string][]string
}

// NewEvaluator creates a new Evaluator and loads rules from filePath.
func NewEvaluator(filePath string) (*Evaluator, error) {
	e := &Evaluator{
		rolesMap: make(map[string]map[string][]string),
	}

	if filePath != "" {
		if err := e.LoadFromFile(filePath); err != nil {
			return nil, err
		}
	}

	return e, nil
}

// NewEvaluatorFromString creates a new Evaluator directly from a JSON string (for K8s Secret / ENV).
func NewEvaluatorFromString(jsonStr string) (*Evaluator, error) {
	e := &Evaluator{
		rolesMap: make(map[string]map[string][]string),
	}
	if err := e.LoadFromString(jsonStr); err != nil {
		return nil, err
	}
	return e, nil
}

// LoadFromBytes parses permissions from JSON bytes.
func (e *Evaluator) LoadFromBytes(data []byte) error {
	var pf PermissionsFile
	if err := json.Unmarshal(data, &pf); err != nil {
		return fmt.Errorf("parse permissions json: %w", err)
	}

	e.mu.Lock()
	defer e.mu.Unlock()

	// Parse role permissions
	newRoles := make(map[string]map[string][]string)
	for _, rp := range pf.Roles {
		roleKey := strings.ToLower(strings.TrimSpace(rp.Role))
		methodMap := make(map[string][]string)
		for method, patterns := range rp.Permissions {
			methodMap[strings.ToUpper(strings.TrimSpace(method))] = patterns
		}
		newRoles[roleKey] = methodMap
	}
	e.rolesMap = newRoles
	return nil
}

// LoadFromString parses permissions from a JSON string.
func (e *Evaluator) LoadFromString(jsonStr string) error {
	return e.LoadFromBytes([]byte(jsonStr))
}

// LoadFromFile reads and parses permissions from a JSON file.
func (e *Evaluator) LoadFromFile(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("read permissions file '%s': %w", filePath, err)
	}
	return e.LoadFromBytes(data)
}


// IsAllowed checks if ANY of the user's roles has permission for the given method and path.
func (e *Evaluator) IsAllowed(roles []string, method, requestPath string) bool {
	e.mu.RLock()
	defer e.mu.RUnlock()

	method = strings.ToUpper(strings.TrimSpace(method))

	for _, role := range roles {
		roleKey := strings.ToLower(strings.TrimSpace(role))
		methodMap, exists := e.rolesMap[roleKey]
		if !exists {
			continue
		}

		// Check wildcard method or specific method
		allowedPatterns := methodMap[method]
		if len(allowedPatterns) == 0 {
			allowedPatterns = methodMap["*"]
		}

		if isPathAllowed(requestPath, allowedPatterns) {
			return true
		}
	}

	return false
}

// isPathAllowed checks if requestPath matches any pattern in allowedPatterns.
func isPathAllowed(requestPath string, allowedPatterns []string) bool {
	requestPath = path.Clean("/" + requestPath)
	if requestPath != "/" {
		requestPath = strings.TrimSuffix(requestPath, "/")
	}

	for _, pattern := range allowedPatterns {
		if pattern == "*" {
			return true
		}
		pattern = path.Clean("/" + pattern)
		if pattern != "/" {
			pattern = strings.TrimSuffix(pattern, "/")
		}

		if matchSinglePattern(requestPath, pattern) {
			return true
		}
		if strings.HasPrefix(requestPath, "/api/v1") && matchSinglePattern(strings.TrimPrefix(requestPath, "/api/v1"), pattern) {
			return true
		}
		if strings.HasPrefix(pattern, "/api/v1") && matchSinglePattern(requestPath, strings.TrimPrefix(pattern, "/api/v1")) {
			return true
		}
	}
	return false
}

func matchSinglePattern(requestPath, pattern string) bool {
	if strings.HasSuffix(pattern, "/*") {
		prefix := strings.TrimSuffix(pattern, "/*")
		if strings.HasPrefix(requestPath, prefix) {
			if requestPath == prefix || strings.HasPrefix(requestPath[len(prefix):], "/") {
				return true
			}
		}
		return false
	}

	reqSegments := strings.Split(requestPath, "/")
	patSegments := strings.Split(pattern, "/")
	if len(reqSegments) != len(patSegments) {
		return false
	}
	return matchPathPattern(reqSegments, patSegments)
}

func matchPathPattern(reqSegments, patSegments []string) bool {
	for i := 0; i < len(reqSegments); i++ {
		if patSegments[i] == reqSegments[i] {
			continue
		}
		if strings.HasPrefix(patSegments[i], ":") {
			if reqSegments[i] == "" {
				return false
			}
			continue
		}
		return false
	}
	return true
}
