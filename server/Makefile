.PHONY: install run build test docker-up docker-down deps

install:
	go mod download

run:
	go run ./cmd/main.go

build:
	go build -o bin/server ./cmd/main.go

test:
	go test ./...

docker-up:
	docker compose up --build

docker-down:
	docker compose down

deps:
	docker compose run --rm server go get $(pkg) && docker compose run --rm server go mod tidy
