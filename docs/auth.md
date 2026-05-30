# Auth endpoints - run and test guide

Covers issue #7: user registration, email verification, and password reset.

## Requirements

Only Docker is needed. No Go, no local database setup.

## Start the stack

```bash
docker compose up --build
```

First run downloads images and dependencies - takes a few minutes. After that it is fast.

## Run migrations

In a second terminal:

```bash
docker compose run --rm server go run ./cmd/migrate/main.go up
```

This creates all tables including `email_verifications` and `password_reset_tokens`.

## Check emails

Open **http://localhost:8025** in your browser. This is Mailpit - it catches every email the server sends. No real email address or credentials needed.

## Test the endpoints

### Register

```bash
curl -X POST http://localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"yourpassword"}'
```

Expected response `201`:
```json
{"message": "registration successful, check your email to verify your account"}
```

Go to **http://localhost:8025** - you will see the verification email. Copy the token from the link.

### Verify email

```bash
curl "http://localhost:8081/api/v1/auth/verify-email?token=PASTE-TOKEN-HERE"
```

Expected response `200`:
```json
{"message": "email verified successfully"}
```

### Forgot password

```bash
curl -X POST http://localhost:8081/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com"}'
```

Expected response `200`:
```json
{"message": "if that email is registered, a reset link has been sent"}
```

Go to **http://localhost:8025** - copy the token from the reset email.

### Reset password

```bash
curl -X POST http://localhost:8081/api/v1/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token":"PASTE-TOKEN-HERE","password":"yournewpassword"}'
```

Expected response `200`:
```json
{"message": "password reset successful"}
```

## Error codes

| Code | Meaning |
|---|---|
| `EMAIL_IN_USE` | Email already registered |
| `INVALID_EMAIL` | Email format is invalid |
| `WEAK_PASSWORD` | Password is under 8 characters |
| `INVALID_TOKEN` | Token not found or already used |
| `TOKEN_EXPIRED` | Reset link older than 1 hour |
| `TOKEN_USED` | Reset link already used once |

## Stop the stack

```bash
docker compose down        # stop, keep data
docker compose down -v     # stop and wipe the database
```
