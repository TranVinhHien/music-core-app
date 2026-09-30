-- +goose Up
-- +goose StatementBegin

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS postgis;
-- CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS user_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    provider VARCHAR(50) DEFAULT 'local', -- 'local', 'google', 'apple'
    provider_id VARCHAR(255), 
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id UUID PRIMARY KEY REFERENCES user_credentials(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    phone_number VARCHAR(20),
    home_address TEXT,
    
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    current_checkin_at TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_credentials(id) ON DELETE CASCADE,
    
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL, -- Token expiration time
    is_revoked BOOLEAN DEFAULT FALSE, -- Revocation status for logout or password changes
    
    -- Optional security tracking fields (login device and IP address)
    client_ip VARCHAR(45),
    user_agent TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for efficient token validation and user queries
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS user_profiles ;
DROP TABLE IF EXISTS user_credentials ;
-- +goose StatementEnd
