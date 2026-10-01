//go:build integration

package integration

import (
	"context"
	"fmt"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/database"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/database/migrations"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/repository"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/router"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/testcontainers/testcontainers-go"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"os"
	"testing"
	"time"
)

var testDB *gorm.DB
var testRouter *gin.Engine

func TestMain(m *testing.M) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	container, err := tcpostgres.Run(ctx, "postgres:16-alpine", tcpostgres.WithDatabase("music_core_integration"), tcpostgres.WithUsername("test"), tcpostgres.WithPassword("test"), tcpostgres.BasicWaitStrategies())
	if err != nil {
		fmt.Fprintf(os.Stderr, "start postgres container: %v\n", err)
		os.Exit(1)
	}
	exitCode := 1
	defer func() {
		if testDB != nil {
			if sqlDB, dbErr := testDB.DB(); dbErr == nil {
				_ = sqlDB.Close()
			}
		}
		if err := testcontainers.TerminateContainer(container); err != nil {
			fmt.Fprintf(os.Stderr, "terminate postgres container: %v\n", err)
			exitCode = 1
		}
		os.Exit(exitCode)
	}()
	uri, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		fmt.Fprintf(os.Stderr, "postgres connection string: %v\n", err)
		return
	}
	testDB, err = gorm.Open(postgres.Open(uri), &gorm.Config{Logger: logger.Default.LogMode(logger.Silent)})
	if err != nil {
		fmt.Fprintf(os.Stderr, "open postgres: %v\n", err)
		return
	}
	if err = database.Migrate(testDB, migrations.FS, "."); err != nil {
		fmt.Fprintf(os.Stderr, "migrate postgres: %v\n", err)
		return
	}
	config.App.Token.Secret = "integration-secret"
	config.App.Token.AccessTokenExpirationTime = 3600
	config.App.Token.RefreshTokenExpirationTime = 3600
	repo := repository.NewUserRepository(testDB)
	auth := services.NewAuthService(repo)
	upload, err := services.NewUploadService()
	if err != nil {
		fmt.Fprintf(os.Stderr, "create upload service: %v\n", err)
		return
	}
	testRouter = router.SetupRouter(handlers.NewAuthHandler(auth), auth, handlers.NewUploadHandler(upload))
	exitCode = m.Run()
}
