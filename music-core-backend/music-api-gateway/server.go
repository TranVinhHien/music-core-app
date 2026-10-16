package gateway

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/middlewares"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// Server encapsulates the Gateway engine, configuration, and routing logic.
type Server struct {
	cfg    *config.Config
	logger *zerolog.Logger
	engine *gin.Engine
}

// NewServer initializes the Gin engine, registers middleware, and configures routes.
func NewServer(cfg *config.Config, logger *zerolog.Logger) *Server {
	if cfg.HttpServer.Mode != "" {
		gin.SetMode(cfg.HttpServer.Mode)
	}

	engine := gin.New()
	engine.RedirectTrailingSlash = false
	engine.RedirectFixedPath = false

	engine.Use(gin.Recovery())
	engine.Use(middlewares.RequestID())
	if logger != nil {
		engine.Use(middlewares.Logger(logger))
	}

	// CORS middleware
	engine.Use(corsMiddleware(cfg))

	s := &Server{
		cfg:    cfg,
		logger: logger,
		engine: engine,
	}

	s.setupRoutes()
	return s
}

func corsMiddleware(cfg *config.Config) gin.HandlerFunc {
	allowOrigins := "*"
	if len(cfg.HttpServer.AllowOrigins) > 0 && cfg.HttpServer.AllowOrigins[0] != "" {
		allowOrigins = strings.Join(cfg.HttpServer.AllowOrigins, ", ")
	}

	allowMethods := "GET, POST, PUT, PATCH, DELETE, OPTIONS"
	if len(cfg.HttpServer.AllowMethods) > 0 {
		allowMethods = strings.Join(cfg.HttpServer.AllowMethods, ", ")
	}

	allowHeaders := "Origin, Content-Type, Accept, Authorization, X-Request-ID, X-User-ID"
	if len(cfg.HttpServer.AllowHeaders) > 0 {
		allowHeaders = strings.Join(cfg.HttpServer.AllowHeaders, ", ")
	}

	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", allowOrigins)
		c.Writer.Header().Set("Access-Control-Allow-Methods", allowMethods)
		c.Writer.Header().Set("Access-Control-Allow-Headers", allowHeaders)
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

func (s *Server) setupRoutes() {
	// Gateway health check endpoint
	s.engine.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": s.cfg.App.Name,
			"version": s.cfg.App.Version,
			"status":  "OK",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// Auth middleware placeholder (as requested: auth check is deferred)
	authMiddleware := middlewares.AuthMiddleware(s.logger)

	for _, route := range s.cfg.Gateway.Routes {
		target := route.Target
		prefix := strings.TrimRight(route.Prefix, "/")
		if target == "" || prefix == "" {
			continue
		}

		handler, err := NewReverseProxyHandler(target, s.logger)
		if err != nil {
			if s.logger != nil {
				s.logger.Error().
					Err(err).
					Str("prefix", prefix).
					Str("target", target).
					Msg("[Gateway] Failed to create proxy handler")
			}
			continue
		}

		if s.logger != nil {
			authStatus := "public"
			if route.AuthRequired {
				authStatus = "protected (placeholder auth)"
			}
			s.logger.Info().
				Str("prefix", prefix+"/*").
				Str("target", target).
				Str("auth", authStatus).
				Msg("[Gateway] Route configured")
		}

		proxyFunc := handler.Handle()

		if route.AuthRequired {
			s.engine.Any(prefix, authMiddleware, proxyFunc)
			s.engine.Any(prefix+"/*any", authMiddleware, proxyFunc)
		} else {
			s.engine.Any(prefix, proxyFunc)
			s.engine.Any(prefix+"/*any", proxyFunc)
		}
	}

	// 404 handler for unmatched routes
	s.engine.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    "404",
			"message": fmt.Sprintf("Gateway: route not found for %s %s", c.Request.Method, c.Request.URL.Path),
			"meta":    nil,
			"data":    nil,
		})
	})
}

// Engine returns the underlying Gin engine.
func (s *Server) Engine() *gin.Engine {
	return s.engine
}

// Run starts the gateway HTTP server.
func (s *Server) Run() error {
	addr := fmt.Sprintf("%s:%d", s.cfg.HttpServer.Host, s.cfg.HttpServer.Port)
	if s.logger != nil {
		s.logger.Info().
			Str("service", s.cfg.App.Name).
			Str("address", addr).
			Msg("[Gateway] Service is listening")
	}
	return s.engine.Run(addr)
}
