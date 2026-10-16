package main

import (
	"flag"
	"log"
	"os"
	"strings"
	"time"

	gateway "github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/permissions"
	"github.com/rs/zerolog"
)

var (
	confPath = flag.String("config", "", "Path to gateway config yaml file")
	permPath = flag.String("permissions", "", "Path to permissions.json file")
)

func findDefaultFile(candidates []string) string {
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}
	return candidates[0]
}

func main() {
	flag.Parse()

	targetConfig := config.ResolveConfigFile(*confPath)

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

	// Load permissions evaluator:
	// Priority 1: Inline JSON from K8s Secret / ConfigMap / ENV (PERMISSIONS_CONTENT / PERMISSIONS_JSON)
	// Priority 2: Command line flag --permissions
	// Priority 3: Config file_path / PERMISSIONS_FILE / PERMISSIONS_FILE_PATH
	// Priority 4: Candidate search paths
	var evaluator *permissions.Evaluator
	if strings.TrimSpace(cfg.Permissions.Content) != "" {
		evaluator, err = permissions.NewEvaluatorFromString(cfg.Permissions.Content)
		if err != nil {
			zlogger.Warn().Err(err).Msg("Warning: failed to parse inline permissions content, falling back to file")
		} else {
			zlogger.Info().Msg("Loaded role permissions successfully from inline JSON (K8s Secret/ENV)")
		}
	}

	if evaluator == nil {
		targetPermFile := *permPath
		if targetPermFile == "" {
			targetPermFile = cfg.Permissions.FilePath
		}
		if _, err := os.Stat(targetPermFile); err != nil {
			targetPermFile = findDefaultFile([]string{
				"./config/permissions.json",
				"./permissions.json",
				"/etc/gateway/permissions.json",
				"./music-api-gateway/config/permissions.json",
				"../config/permissions.json",
			})
		}

		evaluator, err = permissions.NewEvaluator(targetPermFile)
		if err != nil {
			zlogger.Warn().Err(err).Str("file", targetPermFile).Msg("Warning: failed to load permissions file, using empty evaluator")
			evaluator, _ = permissions.NewEvaluator("")
		} else {
			zlogger.Info().Str("permissions_file", targetPermFile).Msg("Loaded role permissions successfully from file")
		}
	}

	server := gateway.NewServer(cfg, &zlogger, evaluator)
	if err := server.Run(); err != nil {
		log.Fatalf("Failed to start gateway server: %v", err)
	}
}
