package config

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App              AppMetadataConfig      `mapstructure:"app"`
	HttpServer       HttpServerConfig       `mapstructure:"http_server"`
	GRPCClient       GRPCClientConfig       `mapstructure:"grpc_client"`
	Logger           LoggerConfig           `mapstructure:"logger"`
	Kafka            KafkaConfig            `mapstructure:"kafka"`
	CockroachDB      CockroachConfig        `mapstructure:"cockroach_db"`
	Token            TokenConfig            `mapstructure:"token"`
	Redis            RedisConfig            `mapstructure:"redis"`
	ExternalServices ExternalServicesConfig `mapstructure:"external_services"`
	AWS              AWSConfig              `mapstructure:"aws"`
}

type AppMetadataConfig struct {
	Name    string `mapstructure:"name"`
	Version string `mapstructure:"version"`
}

type HttpServerConfig struct {
	Host         string   `mapstructure:"host"`
	Port         int      `mapstructure:"port"`
	GRPCPort     int      `mapstructure:"grpc_port"`
	AllowOrigins []string `mapstructure:"allow_origins"`
	AllowMethods []string `mapstructure:"allow_methods"`
	AllowHeaders []string `mapstructure:"allow_headers"`
	Mode         string   `mapstructure:"mode"`
	LogLevel     string   `mapstructure:"log_level"`
}

type GRPCClientConfig struct {
	Host string `mapstructure:"host"`
	Port int    `mapstructure:"port"`
}

type LoggerConfig struct {
	Level string `mapstructure:"level"`
}

type KafkaConfig struct {
	Brokers []string `mapstructure:"brokers"`
}

type CockroachConfig struct {
	Host            string        `mapstructure:"host"`
	Port            int           `mapstructure:"port"`
	User            string        `mapstructure:"user"`
	Password        string        `mapstructure:"password"`
	DBName          string        `mapstructure:"db_name"`
	SSLMode         string        `mapstructure:"ssl_mode"`
	MaxOpenConns    int           `mapstructure:"max_open_conns"`
	MaxIdleConns    int           `mapstructure:"max_idle_conns"`
	ConnMaxLifetime time.Duration `mapstructure:"conn_max_lifetime"`
	LogLevel        string        `mapstructure:"log_level"`
}

type TokenConfig struct {
	Secret                     string `mapstructure:"secret"`
	AccessTokenExpirationTime  int    `mapstructure:"access_token_expiration_time"`
	RefreshTokenExpirationTime int    `mapstructure:"refresh_token_expiration_time"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type ExternalServicesConfig struct {
	// Add fields if needed
}

type AWSConfig struct {
	Region          string `mapstructure:"region"`
	AccessKeyID     string `mapstructure:"access_key_id"`
	SecretAccessKey string `mapstructure:"secret_access_key"`
	BucketName      string `mapstructure:"bucket_name"`
}

var App Config

// ResolveConfigFile finds the user service configuration file path.
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
	if envPath := os.Getenv("APP_CONFIG"); envPath != "" {
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
		fmt.Sprintf("app.%s.yaml", appEnv),
		fmt.Sprintf("./config/app.%s.yaml", appEnv),
		"app.yaml",
		"./config/app.yaml",
		"/etc/user-service/app.yaml",
		fmt.Sprintf("./music-user-service/app.%s.yaml", appEnv),
		fmt.Sprintf("../music-user-service/app.%s.yaml", appEnv),
		fmt.Sprintf("../app.%s.yaml", appEnv),
	}

	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}

	return candidates[0]
}

// LoadConfig loads the user service configuration from file and environment variables.
func LoadConfig(path string) (*Config, error) {
	v := viper.New()
	targetPath := ResolveConfigFile(path)
	v.SetConfigFile(targetPath)
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_", "-", "_"))
	v.AutomaticEnv()

	// Default values
	v.SetDefault("app.name", "music-user-service")
	v.SetDefault("app.version", "v1.0.0")
	v.SetDefault("http_server.host", "0.0.0.0")
	v.SetDefault("http_server.port", 8080)
	v.SetDefault("http_server.mode", "debug")
	v.SetDefault("http_server.log_level", "info")
	v.SetDefault("cockroach_db.host", "localhost")
	v.SetDefault("cockroach_db.port", 5432)
	v.SetDefault("cockroach_db.user", "postgres")
	v.SetDefault("cockroach_db.password", "postgres")
	v.SetDefault("cockroach_db.db_name", "music-core-db")
	v.SetDefault("cockroach_db.ssl_mode", "disable")
	v.SetDefault("cockroach_db.max_open_conns", 25)
	v.SetDefault("cockroach_db.max_idle_conns", 5)
	v.SetDefault("cockroach_db.conn_max_lifetime", time.Hour)
	v.SetDefault("token.secret", "change-me-to-a-long-random-secret")
	v.SetDefault("token.access_token_expiration_time", 3600)
	v.SetDefault("token.refresh_token_expiration_time", 86400)

	// Bind environment variables for Docker Compose and K8s Secrets
	_ = v.BindEnv("http_server.port", "PORT", "SERVER_PORT", "HTTP_SERVER_PORT")
	_ = v.BindEnv("http_server.host", "HOST", "SERVER_HOST", "HTTP_SERVER_HOST")
	_ = v.BindEnv("http_server.mode", "GIN_MODE", "HTTP_SERVER_MODE")
	_ = v.BindEnv("cockroach_db.host", "DB_HOST", "COCKROACH_DB_HOST", "DATABASE_HOST", "POSTGRES_HOST")
	_ = v.BindEnv("cockroach_db.port", "DB_PORT", "COCKROACH_DB_PORT", "DATABASE_PORT", "POSTGRES_PORT")
	_ = v.BindEnv("cockroach_db.user", "DB_USER", "COCKROACH_DB_USER", "DATABASE_USER", "POSTGRES_USER")
	_ = v.BindEnv("cockroach_db.password", "DB_PASSWORD", "COCKROACH_DB_PASSWORD", "DATABASE_PASSWORD", "POSTGRES_PASSWORD")
	_ = v.BindEnv("cockroach_db.db_name", "DB_NAME", "COCKROACH_DB_NAME", "DATABASE_NAME", "POSTGRES_DB")
	_ = v.BindEnv("cockroach_db.ssl_mode", "DB_SSLMODE", "COCKROACH_DB_SSLMODE")
	_ = v.BindEnv("token.secret", "JWT_SECRET", "TOKEN_SECRET")
	_ = v.BindEnv("token.access_token_expiration_time", "ACCESS_TOKEN_EXPIRATION_TIME")
	_ = v.BindEnv("token.refresh_token_expiration_time", "REFRESH_TOKEN_EXPIRATION_TIME")
	_ = v.BindEnv("aws.region", "AWS_REGION")
	_ = v.BindEnv("aws.access_key_id", "AWS_ACCESS_KEY_ID")
	_ = v.BindEnv("aws.secret_access_key", "AWS_SECRET_ACCESS_KEY")
	_ = v.BindEnv("aws.bucket_name", "AWS_BUCKET_NAME", "S3_BUCKET_NAME")

	if err := v.ReadInConfig(); err != nil {
		if !os.IsNotExist(err) && !strings.Contains(err.Error(), "no such file") {
			return nil, fmt.Errorf("failed to read user service config file '%s': %w", targetPath, err)
		}
	}

	var conf Config
	if err := v.Unmarshal(&conf); err != nil {
		return nil, fmt.Errorf("failed to unmarshal user service config: %w", err)
	}

	return &conf, nil
}

// Load initializes the global App config using automatic path resolution.
func Load() error {
	conf, err := LoadConfig("")
	if err != nil {
		return err
	}
	App = *conf
	return nil
}
