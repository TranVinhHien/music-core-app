package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/database"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/logging"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/repository"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/router"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/services"
)

var confPath = flag.String("config", "", "Path to listening event service config yaml file")

func main() {
	flag.Parse()

	targetConfig := config.ResolveConfigFile(*confPath)
	conf, err := config.LoadConfig(targetConfig)
	if err != nil {
		log.Fatalf("Invalid configuration: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Connect to MongoDB
	mg, err := database.ConnectMongoDB(ctx, &conf.MongoDB)
	if err != nil {
		logging.Error(ctx, "main.ConnectMongoDB", err)
		log.Fatalf("Failed to connect to MongoDB: %v", err)
	}
	defer func() {
		disconnectCtx, disconnectCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer disconnectCancel()
		_ = mg.Disconnect(disconnectCtx)
	}()

	logging.Info(ctx, "main", fmt.Sprintf("Connected to MongoDB at %s, database: %s", conf.MongoDB.URI, conf.MongoDB.Database))

	// Initialize layers
	eventRepo := repository.NewEventRepository(mg.Database, conf.MongoDB.Collection)
	eventService := services.NewEventService(eventRepo)
	eventHandler := handlers.NewEventHandler(eventService)

	r := router.SetupRouter(eventHandler)

	addr := fmt.Sprintf("%s:%d", conf.HttpServer.Host, conf.HttpServer.Port)
	srv := &http.Server{
		Addr:    addr,
		Handler: r,
	}

	go func() {
		logging.Info(ctx, "main", fmt.Sprintf("Listening event service starting on %s", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server listen failed: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logging.Info(ctx, "main", "Shutting down listening event service...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logging.Error(ctx, "main.Shutdown", err)
	}
	logging.Info(ctx, "main", "Listening event service stopped gracefully")
}
