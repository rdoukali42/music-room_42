# Music Room

A collaborative music experience platform where users can vote on tracks, control playback, and manage playlists together in real time.

## Requirements

You only need [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed. No Go, no database setup — Docker handles everything.

## Getting Started

**1. Clone the repo**

```bash
git clone https://github.com/Abdelilah99/music-room_42.git
cd music-room_42
```

**2. Set up your environment file**

```bash
cp server/.env.example server/.env
```

The default values work out of the box for local development.

**3. Start the stack**

```bash
docker compose up --build
```

First run takes a few minutes (downloading images and dependencies). Every run after that is fast.

**4. Verify it's running**

```bash
curl http://localhost:8081/health
# {"status":"ok"}
```

## Project Structure

```
music-room_42/
├── docker-compose.yml        # starts the full local stack
├── server/                   # Go backend
│   ├── cmd/
│   │   └── main.go           # entry point
│   ├── internal/
│   │   ├── handler/          # HTTP route handlers
│   │   ├── service/          # business logic
│   │   ├── repository/       # database queries
│   │   ├── model/            # data structures
│   │   └── middleware/       # auth, logging, etc.
│   ├── migrations/           # SQL migration files
│   ├── Dockerfile            # production image
│   ├── Dockerfile.dev        # development image with live reload
│   ├── .env.example          # environment variable template
│   ├── go.mod                # Go dependencies
│   └── Makefile              # common command shortcuts
└── .github/
    └── workflows/
        └── ci.yml            # CI pipeline (build, test, lint)
```

## Daily Workflow

Start and stop:

```bash
docker compose up --build   # start everything
docker compose down         # stop (data is preserved)
docker compose down -v      # stop and wipe the database
```

View logs:

```bash
docker compose logs server -f
docker compose logs postgres -f
```

The server automatically recompiles when you save a `.go` file. No need to restart Docker.

To add a new library:

```bash
make deps pkg=github.com/some/library
```

This updates `go.mod` and `go.sum` on your machine. Commit both files after.

## Environment Variables

| Variable | Description |
|---|---|
| `PORT` | Port the server listens on (default: `8080`) |
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret for signing access tokens |
| `JWT_REFRESH_SECRET` | Secret for signing refresh tokens |

Note: `DATABASE_URL` uses `@postgres` as the host, not `localhost`, because inside Docker services reach each other by their service name.

## Branch and PR Rules

- Work on feature branches, never directly on `main` or `features`
- Every PR needs 1 approval before merging
- CI must pass before merging
- Branch naming: `feature/<short-description>`
