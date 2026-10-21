package config

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App        AppMetadataConfig `mapstructure:"app"`
	HttpServer HttpServerConfig  `mapstructure:"http_server"`
	Logger     LoggerConfig      `mapstructure:"logger"`
	MongoDB    MongoDBConfig     `mapstructure:"mongodb"`
	Token      TokenConfig       `mapstructure:"token"`
	Batch      BatchConfig       `mapstructure:"batch"`
}

type AppMetadataConfig struct {
	Name    string `mapstructure:"name"`
	Version string `mapstructure:"version"`
}

type HttpServerConfig struct {
	Host         string   `mapstructure:"host"`
	Port         int      `mapstructure:"port"`
	AllowOrigins []string `mapstructure:"allow_origins"`
	AllowMethods []string `mapstructure:"allow_methods"`
	AllowHeaders []string `mapstructure:"allow_headers"`
	Mode         string   `mapstructure:"mode"`
	LogLevel     string   `mapstructure:"log_level"`
}

type LoggerConfig struct {
	Level  string `mapstructure:"level"`
	Pretty bool   `mapstructure:"pretty"`
}

type MongoDBConfig struct {
	URI                   string        `mapstructure:"uri"`
	Database              string        `mapstructure:"database"`
	Collection            string        `mapstructure:"collection"`
	MaxPoolSize           uint64        `mapstructure:"max_pool_size"`
	MinPoolSize           uint64        `mapstructure:"min_pool_size"`
	ConnectTimeoutSeconds time.Duration `mapstructure:"connect_timeout_seconds"`
}

type TokenConfig struct {
	Secret string `mapstructure:"secret"`
}

type BatchConfig struct {
	MaxBatchSize int `mapstructure:"max_batch_size"`
}

var App *Config

func ResolveConfigFile(customPath string) string {
	if customPath != "" {
		return customPath
	}

	appEnv := os.Getenv("APP_ENV")
	if appEnv == "" {
		appEnv = "development"
	}

	candidates := []string{
		fmt.Sprintf("app.%s.yaml", appEnv),
		"app.yaml",
		"./config/app.yaml",
		fmt.Sprintf("./music-listening-event-service/app.%s.yaml", appEnv),
		fmt.Sprintf("../music-listening-event-service/app.%s.yaml", appEnv),
		fmt.Sprintf("../app.%s.yaml", appEnv),
		"app.example.yaml",
	}

	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}

	return candidates[0]
}

func LoadConfig(path string) (*Config, error) {
	v := viper.New()
	targetPath := ResolveConfigFile(path)
	v.SetConfigFile(targetPath)
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_", "-", "_"))
	v.AutomaticEnv()

	// Default values
	v.SetDefault("app.name", "music-listening-event-service")
	v.SetDefault("app.version", "v1.0.0")
	v.SetDefault("http_server.host", "0.0.0.0")
	v.SetDefault("http_server.port", 3004)
	v.SetDefault("http_server.mode", "debug")
	v.SetDefault("http_server.log_level", "info")
	v.SetDefault("logger.level", "debug")
	v.SetDefault("logger.pretty", true)

	v.SetDefault("mongodb.uri", "mongodb://localhost:27017")
	v.SetDefault("mongodb.database", "music_core_events")
	v.SetDefault("mongodb.collection", "listening_events")
	v.SetDefault("mongodb.max_pool_size", 100)
	v.SetDefault("mongodb.min_pool_size", 10)
	v.SetDefault("mongodb.connect_timeout_seconds", 10)

	v.SetDefault("token.secret", "change-me-to-a-long-random-secret")
	v.SetDefault("batch.max_batch_size", 100)

	// Bind environment variables
	_ = v.BindEnv("http_server.port", "PORT", "SERVER_PORT", "HTTP_SERVER_PORT")
	_ = v.BindEnv("http_server.host", "HOST", "SERVER_HOST", "HTTP_SERVER_HOST")
	_ = v.BindEnv("http_server.mode", "GIN_MODE", "HTTP_SERVER_MODE")

	_ = v.BindEnv("mongodb.uri", "MONGODB_URI", "MONGO_URI", "DATABASE_URL")
	_ = v.BindEnv("mongodb.database", "MONGODB_DATABASE", "MONGO_DB", "MONGO_DATABASE")
	_ = v.BindEnv("mongodb.collection", "MONGODB_COLLECTION", "MONGO_COLLECTION")

	_ = v.BindEnv("token.secret", "JWT_SECRET", "TOKEN_SECRET")
	_ = v.BindEnv("batch.max_batch_size", "MAX_BATCH_SIZE")

	if err := v.ReadInConfig(); err != nil {
		if !os.IsNotExist(err) && !strings.Contains(err.Error(), "no such file") {
			return nil, fmt.Errorf("failed to read listening event config file '%s': %w", targetPath, err)
		}
	}

	var conf Config
	if err := v.Unmarshal(&conf); err != nil {
		return nil, fmt.Errorf("failed to unmarshal listening event config: %w", err)
	}

	App = &conf
	return &conf, nil
}
