run:
	go run cmd/server/main.go

run-gateway:
	go run cmd/gateway/main.go

test:
	go test ./...

build:
	go build -trimpath -o bin/server ./cmd/server

build-gateway:
	go build -trimpath -o bin/gateway ./cmd/gateway

docker-build:
	docker compose build api

docker-up:
	docker compose up -d --build

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f api
