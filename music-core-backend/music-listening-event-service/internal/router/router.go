package router

import (
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/middleware"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/handlers"
	eventMW "github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/middleware"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func SetupRouter(eventHandler *handlers.EventHandler) *gin.Engine {
	r := gin.Default()

	// 1. CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Request-ID", "X-User-ID", "X-User-Email", "X-User-Roles"},
		ExposeHeaders:    []string{"Content-Length", "X-Request-ID"},
		AllowCredentials: true,
	}))

	// 2. Request ID
	r.Use(middleware.RequestID())

	// 3. Health Checks
	r.GET("/health", eventHandler.Health)

	// 4. API v1 routes
	api := r.Group("/api/v1")
	{
		events := api.Group("/listening-events")
		{
			events.GET("/health", eventHandler.Health)

			// Protected ingestion endpoints (require Gateway context or Bearer token)
			events.Use(eventMW.AuthMiddleware())
			{
				events.POST("/batch", eventHandler.IngestBatch)
				events.POST("", eventHandler.IngestBatch)
			}
		}
	}

	return r
}
