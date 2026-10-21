package database

import (
	"context"
	"fmt"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/logging"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type MongoDB struct {
	Client   *mongo.Client
	Database *mongo.Database
}

func ConnectMongoDB(ctx context.Context, cfg *config.MongoDBConfig) (*MongoDB, error) {
	connectTimeout := cfg.ConnectTimeoutSeconds * time.Second
	if connectTimeout <= 0 {
		connectTimeout = 10 * time.Second
	}

	opts := options.Client().
		ApplyURI(cfg.URI).
		SetConnectTimeout(connectTimeout)

	if cfg.MaxPoolSize > 0 {
		opts.SetMaxPoolSize(cfg.MaxPoolSize)
	}
	if cfg.MinPoolSize > 0 {
		opts.SetMinPoolSize(cfg.MinPoolSize)
	}

	client, err := mongo.Connect(opts)
	if err != nil {
		return nil, fmt.Errorf("failed to create mongo client: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := client.Ping(pingCtx, nil); err != nil {
		logging.Error(ctx, "ConnectMongoDB.Ping", err)
		// We still return client even if ping fails temporarily, but report error if preferred
		return nil, fmt.Errorf("failed to ping mongo server: %w", err)
	}

	db := client.Database(cfg.Database)
	mg := &MongoDB{
		Client:   client,
		Database: db,
	}

	// Auto-create required indexes on startup
	if err := mg.ensureIndexes(ctx, cfg.Collection); err != nil {
		logging.Error(ctx, "ConnectMongoDB.ensureIndexes", err)
		// We log warning and don't halt service if collection already indexed
	}

	return mg, nil
}

func (m *MongoDB) ensureIndexes(ctx context.Context, collectionName string) error {
	coll := m.Database.Collection(collectionName)

	indexModels := []mongo.IndexModel{
		// 1. Unique index on event_id for idempotency
		{
			Keys:    bson.D{{Key: "event_id", Value: 1}},
			Options: options.Index().SetUnique(true).SetName("uniq_event_id"),
		},
		// 2. Compound index for querying user's event history
		{
			Keys:    bson.D{{Key: "user_id", Value: 1}, {Key: "occurred_at", Value: -1}},
			Options: options.Index().SetName("idx_user_occurred_at"),
		},
		// 3. Index on session_id for playback session tracking
		{
			Keys:    bson.D{{Key: "session_id", Value: 1}, {Key: "occurred_at", Value: 1}},
			Options: options.Index().SetName("idx_session_occurred_at"),
		},
	}

	idxCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	_, err := coll.Indexes().CreateMany(idxCtx, indexModels)
	if err != nil {
		return fmt.Errorf("create indexes failed: %w", err)
	}

	return nil
}

func (m *MongoDB) Disconnect(ctx context.Context) error {
	if m.Client != nil {
		return m.Client.Disconnect(ctx)
	}
	return nil
}
