package config

import (
	"fmt"
	"strings"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App struct {
		Name    string `mapstructure:"name"`
		Version string `mapstructure:"version"`
	} `mapstructure:"app"`

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

func LoadConfig(path string) (*Config, error) {
	conf := Config{}
	viper.SetConfigFile(path)
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// Bind environment variables to config keys so Docker Compose env variables override YAML defaults
	_ = viper.BindEnv("cockroach_db.host", "DB_HOST", "COCKROACH_DB_HOST")
	_ = viper.BindEnv("cockroach_db.port", "DB_PORT", "COCKROACH_DB_PORT")
	_ = viper.BindEnv("cockroach_db.user", "DB_USER", "COCKROACH_DB_USER")
	_ = viper.BindEnv("cockroach_db.password", "DB_PASSWORD", "COCKROACH_DB_PASSWORD")
	_ = viper.BindEnv("cockroach_db.db_name", "DB_NAME", "COCKROACH_DB_NAME")
	_ = viper.BindEnv("cockroach_db.ssl_mode", "DB_SSLMODE", "COCKROACH_DB_SSLMODE")
	_ = viper.BindEnv("http_server.port", "SERVER_PORT", "PORT")

	err := viper.ReadInConfig()
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	err = viper.Unmarshal(&conf)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return &conf, nil
}

func Load() error {
	conf, err := LoadConfig("app.development.yaml")
	if err != nil {
		return err
	}
	App = *conf
	return nil
}
