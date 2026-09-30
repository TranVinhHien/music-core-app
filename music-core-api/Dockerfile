FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -tags=nomsgpack -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY --from=builder /out/server ./server
COPY --chown=app:app public ./public
COPY --chown=app:app app.development.yaml ./app.development.yaml

USER app

EXPOSE 8080

ENTRYPOINT ["./server"]
