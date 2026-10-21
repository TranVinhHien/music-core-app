package logging

import (
	"context"
	"log"
	"time"
)

func Error(ctx context.Context, location string, err error) {
	if err == nil {
		return
	}
	ts := time.Now().Format(time.RFC3339)
	log.Printf("%s [ERROR] %s: %v", ts, location, err)
}

func Info(ctx context.Context, location string, message string) {
	ts := time.Now().Format(time.RFC3339)
	log.Printf("%s [INFO] %s: %s", ts, location, message)
}
