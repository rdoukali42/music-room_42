package main

import (
	"database/sql"
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file
	_ = godotenv.Load()

	action := "up"
	if len(os.Args) > 1 {
		action = os.Args[1]
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		databaseURL = "postgres://postgres:postgres@localhost:5432/music_room?sslmode=disable"
	}

	log.Printf("Connecting to database for migrations...")
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	log.Printf("Initializing migrations from file://migrations...")
	m, err := migrate.New(
		"file://migrations",
		databaseURL,
	)
	if err != nil {
		log.Fatalf("Failed to initialize migrations system: %v", err)
	}
	defer m.Close()

	switch action {
	case "up":
		log.Printf("Applying database migrations (UP)...")
		if err := m.Up(); err != nil {
			if err == migrate.ErrNoChange {
				log.Println("Database is already up to date. No migrations to apply.")
			} else {
				log.Fatalf("Failed to apply migrations up: %v", err)
			}
		} else {
			log.Println("Database migrations applied successfully!")
		}
	case "down":
		log.Printf("Reverting database migrations (DOWN)...")
		if err := m.Down(); err != nil {
			if err == migrate.ErrNoChange {
				log.Println("No migrations to revert.")
			} else {
				log.Fatalf("Failed to revert migrations down: %v", err)
			}
		} else {
			log.Println("Database migrations reverted successfully!")
		}
	default:
		log.Fatalf("Invalid migration action: %q. Use 'up' or 'down'", action)
	}
}
