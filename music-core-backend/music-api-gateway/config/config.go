package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// Config holds the configuration for the API Gateway service.
type Config struct {
	App        AppConfig        `mapstructure:"app"`
	HttpServer HttpServerConfig `mapstructure:"http_server"`
	Logger     LoggerConfig     `mapstructure:"logger"`
	Gateway    GatewayConfig    `mapstructure:"gateway"`
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

// LoadConfig loads the gateway configuration from the given file path.
func LoadConfig(path string) (*Config, error) {
	v := viper.New()
	v.SetConfigFile(path)
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
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

	// Bind environment variables
	_ = v.BindEnv("http_server.port", "GATEWAY_PORT", "PORT")
	_ = v.BindEnv("http_server.host", "GATEWAY_HOST", "HOST")
	_ = v.BindEnv("http_server.mode", "GIN_MODE")

	if err := v.ReadInConfig(); err != nil {
		if !os.IsNotExist(err) {
			return nil, fmt.Errorf("failed to read gateway config file: %w", err)
		}
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("failed to unmarshal gateway config: %w", err)
	}

	return &cfg, nil
}
