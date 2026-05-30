package main

import (
	"context"
	"log"
	"os"
	"time"

	"music-room/internal/auth"
	"music-room/internal/repository"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

var DBpool *pgxpool.Pool

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, reading from environment")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	log.Println("Connecting to database...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	config, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		log.Fatalf("Failed to parse database URL: %v", err)
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		log.Fatalf("Failed to create database pool: %v", err)
	}
	defer pool.Close()
	
	DBpool = pool
	log.Println("Database connection established")
	if err := DBpool.Ping(ctx); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("Database connection verified")

	// Repositories
	userRepo := repository.NewPostgresUserRepository(DBpool)
	tokenRepo := repository.NewPostgresRefreshTokenRepository(DBpool)

	// Services
	jwtService := auth.NewJWTService()
	authMiddleware := auth.NewMiddleware(jwtService)

	// Handlers
	authHandler := auth.NewHandler(userRepo, tokenRepo, jwtService)

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "UP"})
	})

	authGroup := r.Group("/auth")
	{
		authGroup.POST("/login", authHandler.Login)
		authGroup.POST("/refresh", authHandler.Refresh)
		authGroup.POST("/logout", authHandler.Logout)
	}

	apiGroup := r.Group("/api")
	apiGroup.Use(authMiddleware.Authenticate())
	{
		apiGroup.GET("/profile", func(c *gin.Context) {
			userID, _ := c.Get("user_id")
			email, _ := c.Get("email")
			tier, _ := c.Get("subscription_tier")
			c.JSON(200, gin.H{
				"user_id":           userID,
				"email":            email,
				"subscription_tier": tier,
			})
		})

		apiGroup.GET("/users/:id", auth.RequireOwnership("id"), func(c *gin.Context) {
			userID := c.Param("id")
			c.JSON(200, gin.H{
				"message": "Access granted to user resource",
				"id":      userID,
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

