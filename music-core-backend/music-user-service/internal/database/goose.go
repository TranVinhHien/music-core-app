package database

import (
	"github.com/pressly/goose/v3"
	"github.com/rs/zerolog/log"
)

type GooseLogger struct {
}

func (l *GooseLogger) Fatalf(format string, args ...interface{}) {
	log.Fatal().Msgf(format, args...)
}

func (l *GooseLogger) Printf(format string, args ...interface{}) {
	log.Info().Msgf(format, args...)
}

var _ goose.Logger = (*GooseLogger)(nil)
