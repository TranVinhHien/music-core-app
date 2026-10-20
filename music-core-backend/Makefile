run-gateway:
	cd music-api-gateway && go run cmd/main.go

run-user:
	cd music-user-service && go run cmd/server/main.go

run-catalog:
	cd music-catalog-service && npm run wdev

run-library:
	cd music-library-service && npm run wdev

build-gateway:
	cd music-api-gateway && go build -trimpath -o bin/gateway ./cmd

build-user:
	cd music-user-service && go build -trimpath -o bin/server ./cmd/server

build-catalog:
	cd music-catalog-service && npm run build

build-library:
	cd music-library-service && npm run build

# --- Migration Commands ---
migrate-catalog:
	cd music-catalog-service && npm run prisma:deploy

migrate-catalog-dev:
	cd music-catalog-service && npm run prisma:migrate

migrate-catalog-down:
	cd music-catalog-service && npm run prisma:down

migrate-catalog-status:
	cd music-catalog-service && npm run prisma:status

migrate-library:
	cd music-library-service && npm run prisma:deploy

migrate-library-dev:
	cd music-library-service && npm run prisma:migrate

migrate-library-down:
	cd music-library-service && npm run prisma:down

migrate-library-status:
	cd music-library-service && npm run prisma:status

test-gateway:
	cd music-api-gateway && go test -v ./...

test-user:
	cd music-user-service && go test -v ./...

test-catalog:
	cd music-catalog-service && npm test

test-library:
	cd music-library-service && npm test

test-common:
	cd music-common && go test -v ./...

test-all: test-common test-gateway test-user test-catalog test-library
