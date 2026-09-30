package main

import (
	"fmt"
	"log"

	_ "github.com/TranVinhHien/music-core-app/music-core-api/docs"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/database"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/database/migrations"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/repository"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/router"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/services"
)

// @title Plan-Travel API
// @version 1.0
// @description This is a sample server for Plan-Travel.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host localhost:8080
// @BasePath /api
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	if err := config.Load(); err != nil {
		log.Fatalf("Invalid configuration: %v", err)
	}

	// Connect to database
	database.Connect()
	defer database.Close()

	db := database.GetDB()
	err := database.Migrate(db, migrations.FS, ".")
	if err != nil {
		fmt.Println("Failed to migrate database", err)
		return
	}
	fmt.Println("Database migrated successfully")

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)

	// Initialize services
	authService := services.NewAuthService(userRepo)
	uploadService, err := services.NewUploadService()
	if err != nil {
		log.Fatalf("Failed to initialize UploadService: %v", err)
	}
	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	uploadHandler := handlers.NewUploadHandler(uploadService)

	// Setup Router
	r := router.SetupRouter(authHandler, authService, uploadHandler)

	// Start server
	port := config.App.HttpServer.Port
	if port == 0 {
		port = 8080
	}
	address := fmt.Sprintf(":%d", port)
	log.Printf("Server starting on %s", address)
	if err := r.Run(address); err != nil {
		log.Fatalf("Server stopped: %v", err)
	}
}
