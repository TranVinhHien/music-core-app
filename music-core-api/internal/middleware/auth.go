package middleware

import (
	"net/http"
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	_ "github.com/joho/godotenv"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
)

type Claims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, dto.Response{Code: "401", Message: "Authorization header required", Meta: nil, Data: nil})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, dto.Response{Code: "401", Message: "Invalid authorization format", Meta: nil, Data: nil})
			c.Abort()
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.App.Token.Secret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, dto.Response{Code: "401", Message: "Invalid or expired token", Meta: nil, Data: nil})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("email", claims.Email)
		c.Next()
	}
}

func GetUserID(c *gin.Context) string {
	userID, exists := c.Get("user_id")
	if !exists {
		return ""
	}
	return userID.(string)
}

func ParseUUID(s string) uuid.UUID {
	id, _ := uuid.Parse(s)
	return id
}
