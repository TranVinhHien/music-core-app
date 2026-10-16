package main

import (
	"flag"
	"log"
	"os"
	"time"

	gateway "github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/config"
	"github.com/rs/zerolog"
)

var (
	confPath = flag.String("config", "", "Path to gateway config yaml file")
)

func findDefaultConfig() string {
	candidates := []string{
		"./config/gateway.development.yaml",
		"./music-api-gateway/config/gateway.development.yaml",
		"../config/gateway.development.yaml",
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}
	return "./config/gateway.development.yaml"
}

func main() {
	flag.Parse()

	targetConfig := *confPath
	if targetConfig == "" {
		if envConf := os.Getenv("GATEWAY_CONFIG"); envConf != "" {
			targetConfig = envConf
		} else {
			targetConfig = findDefaultConfig()
		}
	}

	cfg, err := config.LoadConfig(targetConfig)
	if err != nil {
		log.Fatalf("Failed to load gateway configuration from '%s': %v", targetConfig, err)
	}

	// Initialize zerolog
	level, err := zerolog.ParseLevel(cfg.Logger.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)

	var zlogger zerolog.Logger
	if cfg.Logger.Pretty {
		zlogger = zerolog.New(zerolog.ConsoleWriter{
			Out:        os.Stdout,
			TimeFormat: time.RFC3339,
		}).With().Timestamp().Str("service", cfg.App.Name).Logger()
	} else {
		zlogger = zerolog.New(os.Stdout).With().Timestamp().Str("service", cfg.App.Name).Logger()
	}

	zlogger.Info().
		Str("config", targetConfig).
		Int("port", cfg.HttpServer.Port).
		Int("routes_count", len(cfg.Gateway.Routes)).
		Msg("Gateway configuration loaded successfully")

	server := gateway.NewServer(cfg, &zlogger)
	if err := server.Run(); err != nil {
		log.Fatalf("Failed to start gateway server: %v", err)
	}
}
