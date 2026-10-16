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
	if ctx == nil {
		log.Printf("%s [ERROR] %s: %v", ts, location, err)
		return
	}
	log.Printf("%s [ERROR] %s: %v", ts, location, err)
}
