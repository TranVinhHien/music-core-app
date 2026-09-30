package router

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/services"
)

// SetupRouter initializes and configures the gin router
func SetupRouter(
	authHandler *handlers.AuthHandler,
	authService *services.AuthService,
	uploadHandler *handlers.UploadHandler,
) *gin.Engine {
	r := gin.Default()

	// CORS configuration
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// Serve static files
	r.Static("/public", "./public")
	r.GET("/", func(c *gin.Context) { c.File("./public/login.html") })
	r.GET("/login", func(c *gin.Context) { c.File("./public/login.html") })
	r.GET("/dashboard", func(c *gin.Context) { c.File("./public/dashboard.html") })

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, dto.Response{
			Code:    "200",
			Message: "ok",
			Meta:    nil,
			Data:    nil,
		})
	})

	// Swagger documentation
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// API routes
	api := r.Group("/api/v1")
	{
		// Auth routes (public)
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", authHandler.Logout)
			auth.GET("/me", handlers.AuthMiddleware(authService), authHandler.GetMe)
			auth.PUT("/me", handlers.AuthMiddleware(authService), authHandler.UpdateMe)
			auth.PUT("/me/password", handlers.AuthMiddleware(authService), authHandler.UpdatePassword)
		}

		// Protected routes
		protected := api.Group("")
		protected.Use(handlers.AuthMiddleware(authService))
		{
			// Add other protected routes here
			protected.POST("/upload", uploadHandler.UploadImage)
		}
	}

	return r
}
