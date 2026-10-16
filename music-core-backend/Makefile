run-gateway:
	cd music-api-gateway && go run cmd/main.go

run-user:
	cd music-user-service && go run cmd/server/main.go

build-gateway:
	cd music-api-gateway && go build -trimpath -o bin/gateway ./cmd

build-user:
	cd music-user-service && go build -trimpath -o bin/server ./cmd/server

test-gateway:
	cd music-api-gateway && go test -v ./...

test-user:
	cd music-user-service && go test -v ./...

test-common:
	cd music-common && go test -v ./...

test-all: test-common test-gateway test-user
