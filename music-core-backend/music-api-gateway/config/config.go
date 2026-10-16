package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// Config holds the configuration for the API Gateway service.
type Config struct {
	App         AppConfig         `mapstructure:"app"`
	HttpServer  HttpServerConfig  `mapstructure:"http_server"`
	Logger      LoggerConfig      `mapstructure:"logger"`
	Gateway     GatewayConfig     `mapstructure:"gateway"`
	Token       TokenConfig       `mapstructure:"token"`
	Permissions PermissionsConfig `mapstructure:"permissions"`
}

// AppConfig contains metadata about the application.
type AppConfig struct {
	Name    string `mapstructure:"name"`
	Version string `mapstructure:"version"`
}

// HttpServerConfig contains configuration for the HTTP server.
type HttpServerConfig struct {
	Host         string   `mapstructure:"host"`
	Port         int      `mapstructure:"port"`
	AllowOrigins []string `mapstructure:"allow_origins"`
	AllowMethods []string `mapstructure:"allow_methods"`
	AllowHeaders []string `mapstructure:"allow_headers"`
	Mode         string   `mapstructure:"mode"`
	LogLevel     string   `mapstructure:"log_level"`
}

// LoggerConfig defines logging configuration.
type LoggerConfig struct {
	Level  string `mapstructure:"level"`
	Pretty bool   `mapstructure:"pretty"`
}

// GatewayConfig defines reverse proxy routing rules.
type GatewayConfig struct {
	Routes []GatewayRouteConfig `mapstructure:"routes"`
}

// GatewayRouteConfig defines a single route mapping rule.
type GatewayRouteConfig struct {
	Prefix       string `mapstructure:"prefix"`
	Target       string `mapstructure:"target"`
	AuthRequired bool   `mapstructure:"auth_required"`
}

// TokenConfig holds JWT authentication configuration.
type TokenConfig struct {
	Secret string `mapstructure:"secret"`
}

// PermissionsConfig holds the path or inline JSON content for permissions.
type PermissionsConfig struct {
	FilePath string `mapstructure:"file_path"`
	Content  string `mapstructure:"content"` // Support inline JSON from K8s Secret / ConfigMap / ENV
}

// ResolveConfigFile finds the configuration file using candidate paths and environment.
func ResolveConfigFile(customPath string) string {
	if customPath != "" {
		return customPath
	}
	if envPath := os.Getenv("CONFIG_FILE"); envPath != "" {
		return envPath
	}
	if envPath := os.Getenv("CONFIG_PATH"); envPath != "" {
		return envPath
	}
	if envPath := os.Getenv("GATEWAY_CONFIG"); envPath != "" {
		return envPath
	}

	appEnv := os.Getenv("APP_ENV")
	if appEnv == "" {
		appEnv = os.Getenv("ENV")
	}
	if appEnv == "" {
		appEnv = "development"
	}

	candidates := []string{
		fmt.Sprintf("./config/gateway.%s.yaml", appEnv),
		"./config/gateway.yaml",
		fmt.Sprintf("./gateway.%s.yaml", appEnv),
		"./gateway.yaml",
		"/etc/gateway/gateway.yaml",
		fmt.Sprintf("./music-api-gateway/config/gateway.%s.yaml", appEnv),
		"./music-api-gateway/config/gateway.yaml",
		fmt.Sprintf("../config/gateway.%s.yaml", appEnv),
		"../config/gateway.yaml",
	}

	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}

	return candidates[0]
}

// LoadConfig loads the gateway configuration from the given file path or environment variables.
func LoadConfig(path string) (*Config, error) {
	v := viper.New()
	targetPath := ResolveConfigFile(path)
	v.SetConfigFile(targetPath)
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_", "-", "_"))
	v.AutomaticEnv()

	// Default values
	v.SetDefault("app.name", "music-api-gateway")
	v.SetDefault("app.version", "v1.0.0")
	v.SetDefault("http_server.host", "0.0.0.0")
	v.SetDefault("http_server.port", 8000)
	v.SetDefault("http_server.mode", "debug")
	v.SetDefault("http_server.log_level", "info")
	v.SetDefault("logger.level", "info")
	v.SetDefault("logger.pretty", true)
	v.SetDefault("token.secret", "change-me-to-a-long-random-secret")
	v.SetDefault("permissions.file_path", "./config/permissions.json")

	// Bind environment variables for Docker Compose and K8s Secrets
	_ = v.BindEnv("http_server.port", "PORT", "GATEWAY_PORT", "HTTP_SERVER_PORT", "SERVER_PORT")
	_ = v.BindEnv("http_server.host", "HOST", "GATEWAY_HOST", "HTTP_SERVER_HOST", "SERVER_HOST")
	_ = v.BindEnv("http_server.mode", "GIN_MODE", "HTTP_SERVER_MODE")
	_ = v.BindEnv("logger.level", "LOG_LEVEL")
	_ = v.BindEnv("token.secret", "JWT_SECRET", "TOKEN_SECRET")
	_ = v.BindEnv("permissions.file_path", "PERMISSIONS_FILE", "PERMISSIONS_FILE_PATH")
	_ = v.BindEnv("permissions.content", "PERMISSIONS_CONTENT", "PERMISSIONS_JSON")

	if err := v.ReadInConfig(); err != nil {
		if !os.IsNotExist(err) && !strings.Contains(err.Error(), "no such file") {
			return nil, fmt.Errorf("failed to read gateway config file '%s': %w", targetPath, err)
		}
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("failed to unmarshal gateway config: %w", err)
	}

	// Environment variable overrides for microservice upstream targets (Essential for Docker Compose & K8s)
	applyUpstreamTargetOverrides(&cfg)

	return &cfg, nil
}

func applyUpstreamTargetOverrides(cfg *Config) {
	userServiceURL := os.Getenv("USER_SERVICE_URL")
	if userServiceURL == "" {
		userServiceURL = os.Getenv("TARGET_USER_SERVICE")
	}
	catalogServiceURL := os.Getenv("CATALOG_SERVICE_URL")
	if catalogServiceURL == "" {
		catalogServiceURL = os.Getenv("TARGET_CATALOG_SERVICE")
	}
	libraryServiceURL := os.Getenv("LIBRARY_SERVICE_URL")
	if libraryServiceURL == "" {
		libraryServiceURL = os.Getenv("TARGET_LIBRARY_SERVICE")
	}
	listeningEventsURL := os.Getenv("LISTENING_EVENT_SERVICE_URL")
	if listeningEventsURL == "" {
		listeningEventsURL = os.Getenv("TARGET_LISTENING_EVENT_SERVICE")
	}
	audioServiceURL := os.Getenv("AUDIO_SERVICE_URL")
	if audioServiceURL == "" {
		audioServiceURL = os.Getenv("TARGET_AUDIO_SERVICE")
	}

	for i := range cfg.Gateway.Routes {
		r := &cfg.Gateway.Routes[i]
		if userServiceURL != "" && (r.Prefix == "/api/v1/auth" || r.Prefix == "/api/v1/users" || r.Prefix == "/api/v1/upload") {
			r.Target = userServiceURL
		}
		if catalogServiceURL != "" && r.Prefix == "/api/v1/catalog" {
			r.Target = catalogServiceURL
		}
		if libraryServiceURL != "" && r.Prefix == "/api/v1/library" {
			r.Target = libraryServiceURL
		}
		if listeningEventsURL != "" && r.Prefix == "/api/v1/listening-events" {
			r.Target = listeningEventsURL
		}
		if audioServiceURL != "" && r.Prefix == "/api/v1/audio" {
			r.Target = audioServiceURL
		}
	}
}
