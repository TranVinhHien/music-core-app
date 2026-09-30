package database

import (
	"fmt"
	"log"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func Connect() {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.App.CockroachDB.Host,
		config.App.CockroachDB.Port,
		config.App.CockroachDB.User,
		config.App.CockroachDB.Password,
		config.App.CockroachDB.DBName,
		config.App.CockroachDB.SSLMode,
	)

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
	})

	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}

	sqlDB, err := DB.DB()
	if err != nil {
		log.Fatalf("Unable to get database instance: %v", err)
	}

	// Use configured connection limits
	maxOpen := config.App.CockroachDB.MaxOpenConns
	if maxOpen == 0 {
		maxOpen = 25
	}
	maxIdle := config.App.CockroachDB.MaxIdleConns
	if maxIdle == 0 {
		maxIdle = 5
	}
	lifetime := config.App.CockroachDB.ConnMaxLifetime
	if lifetime == 0 {
		lifetime = time.Hour
	}

	sqlDB.SetMaxOpenConns(maxOpen)
	sqlDB.SetMaxIdleConns(maxIdle)
	sqlDB.SetConnMaxLifetime(lifetime)
	sqlDB.SetConnMaxIdleTime(30 * time.Minute)

	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("Unable to ping database: %v", err)
	}

	log.Println("Database connected successfully")
}

func GetDB() *gorm.DB {
	return DB
}

func Close() {
	if DB != nil {
		sqlDB, err := DB.DB()
		if err == nil {
			sqlDB.Close()
			log.Println("Database closed")
		}
	}
}
