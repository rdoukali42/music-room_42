# Music Room - Features Checklist
### Stack: Go (server) · Flutter + Kotlin + Android SDK (mobile)

---

# PART 1 - MANDATORY

---

## 🖥️ SERVER - Go

---

### 1. Project Setup & Architecture

- [ ] **Initialize Go module**
  - `go mod init <module-name>` - no vendored libraries in the repo
- [ ] **Choose and set up a minimal HTTP router/framework**
  - Use `gin-gonic/gin` - minimal, fast, widely documented, handles routing + middleware cleanly
- [ ] **Create a `Makefile`** with targets: `make install` (download deps), `make run`, `make test`, `make build`
- [ ] **Set up `.env` file** for all secrets and config values; load with `joho/godotenv`
- [ ] **Add `.env` to `.gitignore`** - never commit secrets
- [ ] **Define project folder structure:**
  ```
  /cmd          → main entrypoint
  /internal
    /handler    → HTTP handlers (controllers)
    /service    → business logic
    /repository → DB queries
    /model      → structs / domain types
    /middleware → auth, logging, rate-limit
  /migrations   → SQL migration files
  ```

---

### 2. Database & Data Storage

- [ ] **Use PostgreSQL** - single DB for all data; handles transactions, concurrency, and relational data needed by all 3 services
  - Driver: `jackc/pgx` (native Go PostgreSQL driver, faster than `database/sql`)
- [ ] **Design schema** for all entities: `users`, `sessions`, `friends`, `events`, `event_invites`, `tracks`, `votes`, `playlists`, `playlist_tracks`, `playlist_invites`, `devices`, `delegations`, `licenses`, `logs`
- [ ] **Set up migrations** with `golang-migrate/migrate`
  - Plain `.sql` files, applied on startup or via `make migrate`
- [ ] **Write raw SQL queries** via `pgx` directly - no ORM needed to stay minimal
  - Use `pgx.Pool` for connection pooling

---

### 3. User Management

- [ ] **User registration with email + password**
  - Hash passwords with `golang.org/x/crypto/bcrypt` (built into Go's extended stdlib - no extra dependency)
- [ ] **Email validation flow** - generate a UUID token, store it, send a confirmation link by email; mark account as `verified` on click
  - Send emails with Go's built-in `net/smtp` pointed at a free SMTP relay (e.g. Brevo free tier or Gmail SMTP for dev)
  - No external email SDK needed
- [ ] **Password reset flow** - generate a time-limited token (store expiry in DB), send reset link by email, validate token and update password hash
- [ ] **OAuth2 login via Google** - implement the OAuth2 Authorization Code flow manually
  - Use `golang.org/x/oauth2` + `golang.org/x/oauth2/google` (Go extended stdlib - no heavy SDK)
  - Exchange code for token, fetch user info from Google's userinfo endpoint, upsert user record
- [ ] **OAuth2 login via Facebook** - same pattern as Google
  - Use `golang.org/x/oauth2` with Facebook's token and graph API endpoint
- [ ] **Account linking** - if a logged-in user authenticates via OAuth and the email matches an existing account, link the OAuth provider to that account; store `provider` + `provider_id` in a `user_providers` table
- [ ] **User profile** with visibility tiers stored as separate columns or a JSONB field:
  - `public_info`, `friends_info`, `private_info`, `music_preferences`
- [ ] **Friend system** - `friendships` table with status (`pending`, `accepted`); endpoints: send request, accept, reject, unfriend, list friends

---

### 4. Authentication & Sessions

- [ ] **Issue JWTs on login** - short-lived access token (15 min) + long-lived refresh token (7 days)
  - Use `golang-jwt/jwt` (v5)
- [ ] **Store refresh tokens** in a `refresh_tokens` table (hashed); invalidate on logout or rotation
- [ ] **Auth middleware** - `gin` middleware that validates the `Authorization: Bearer <token>` header on protected routes; returns `401` if missing or invalid
- [ ] **Ownership middleware** - check that the requesting user owns the resource being modified; return `403` otherwise
- [ ] **Token rotation** - issue a new refresh token each time one is used; invalidate the old one

---

### 5. API Design

- [ ] **REST API** with `gin` - use proper HTTP verbs (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) and status codes
- [ ] **JSON for all requests and responses** - `gin` handles this natively with `c.JSON()` and `c.ShouldBindJSON()`
- [ ] **Version all routes** under `/api/v1/`
- [ ] **Consistent error envelope:**
  ```json
  { "error": "human-readable message", "code": "MACHINE_CODE" }
  ```
- [ ] **Auto-generate API documentation** with `swaggo/swag`
  - Annotate handlers with `// @Summary`, `// @Param`, `// @Success`, etc.
  - Run `swag init` to produce `swagger.json`; serve it at `/api/v1/docs`

---

### 6. Service - Music Track Vote

- [ ] **`POST /events`** - create an event (name, location lat/lng, radius, visibility, time window)
- [ ] **`GET /events`** - list public events + private events the user is invited to; support search by name/location
- [ ] **`POST /events/:id/invites`** - invite a user to a private event
- [ ] **`POST /events/:id/tracks`** - suggest a track for the event queue
- [ ] **`POST /events/:id/tracks/:trackId/vote`** - cast a vote; bump track up the queue
- [ ] **`GET /events/:id/queue`** - return queue ordered by vote count descending
- [ ] **Real-time queue broadcast** - when a vote lands, push the updated queue to all connected clients
  - Use `gorilla/websocket` - one WebSocket hub per event, broadcast on every vote write
- [ ] **Concurrency on votes** - use a PostgreSQL `UPDATE ... SET votes = votes + 1` inside a transaction; never read-then-write in application code (prevents race conditions at the DB level)
- [ ] **License enforcement (server-side):**
  - License 0 (default): no restriction, anyone can vote
  - License 1: check that `user_id` is in `event_invites` before accepting vote
  - License 2: validate that the request carries GPS coordinates within `event.radius` AND current server time is within `event.vote_start` / `event.vote_end`
- [ ] **Geolocation check** - use the Haversine formula in Go (a few lines, no library needed) to compute distance between user coordinates and event coordinates

---

### 7. Service - Music Control Delegation

- [ ] **`POST /devices`** - register a device (name, platform, model) linked to the authenticated user
- [ ] **`GET /devices`** - list the authenticated user's devices
- [ ] **`POST /devices/:id/delegate`** - grant control of a device to a friend (`friend_user_id` in body)
- [ ] **`DELETE /devices/:id/delegate`** - revoke delegation
- [ ] **`POST /devices/:id/command`** - send a playback command (`play`, `pause`, `next`, `volume`) - only allowed if the sender is the device owner or an active delegate
- [ ] **Real-time command relay** - device owner's app subscribes to a WebSocket channel for their device; commands sent by the delegate are pushed through it
  - Reuse the same `gorilla/websocket` hub pattern, keyed by `device_id`
- [ ] **License is per-device** - the `delegations` table stores which user has control of which device; enforce in middleware

---

### 8. Service - Music Playlist Editor

- [ ] **`POST /playlists`** - create a playlist (name, visibility)
- [ ] **`GET /playlists`** - list public playlists + private playlists the user is invited to
- [ ] **`POST /playlists/:id/invites`** - invite a user to a private playlist
- [ ] **`POST /playlists/:id/tracks`** - add a track (search result from music API passed as body)
- [ ] **`DELETE /playlists/:id/tracks/:trackId`** - remove a track
- [ ] **`PATCH /playlists/:id/tracks/:trackId/position`** - move a track to a new position
- [ ] **Real-time collaboration** - broadcast every add/remove/move event to all clients subscribed to that playlist's WebSocket channel
  - Use `gorilla/websocket` hub keyed by `playlist_id`
- [ ] **Concurrency on reorder** - use a `position` integer column + PostgreSQL advisory locks or a serializable transaction to prevent two simultaneous moves from corrupting order; apply last-write-wins with server timestamp as the tiebreaker
- [ ] **License enforcement:**
  - License 0: anyone can edit
  - License 1: only users in `playlist_invites` can edit; others get read-only access
- [ ] **External music search** - proxy search queries to a music API; return results to the client (the client does not call the music API directly)
  - Use `Deezer public API` (no auth key required for search) via Go's `net/http` - no SDK, just HTTP calls

---

### 9. Security

- [ ] **Rate limiting** on all routes, stricter on `/auth/*`
  - Use `ulule/limiter` with an in-memory store (no Redis needed for minimum viable)
- [ ] **Input validation** on all request bodies
  - Use `go-playground/validator` - tag structs with `validate:"required,email"` etc.; bind + validate in one step with `gin`
- [ ] **SQL injection prevention** - always use parameterized queries via `pgx` (`$1`, `$2` placeholders); never string-concatenate SQL
- [ ] **CORS configuration** - use `gin-contrib/cors`; whitelist only known origins in production
- [ ] **Short-lived JWTs** limit session theft exposure; document the mitigation in a `SECURITY.md`
- [ ] **Document other identified attack vectors** in `SECURITY.md`: CSRF (mitigated by JWT in header), replay attacks (mitigated by token expiry), enumeration attacks (uniform error messages)
- [ ] **Data isolation checks** - every handler that touches a resource must verify `owner_id = authenticated_user_id`

---

### 10. Logging

- [ ] **Structured logging** with Go's built-in `log/slog` (available since Go 1.21 - zero extra dependency)
  - Log level, timestamp, user ID, action, HTTP method + path, status code
- [ ] **Capture mobile metadata** from request headers on every authenticated call:
  - `X-Platform` (android)
  - `X-Device-Model` (e.g. `Samsung Galaxy S24`)
  - `X-App-Version` (e.g. `1.0.3`)
- [ ] **Write logs to stdout** (structured JSON lines) - redirect to a file in production via shell redirect or `systemd` journal; no log aggregation service needed to meet requirements

---

### 11. Ramp-up / Load Testing

- [ ] **Document server specs** in `README.md` (CPU, RAM, OS, local vs. cloud)
- [ ] **Run load tests** with `k6` (simplest scripting model, JS-based, single binary)
  - Write 3 scripts: one per service (Track Vote, Control Delegation, Playlist Editor)
  - Target: find the requests/sec where error rate exceeds 1% or p95 latency exceeds 500ms
- [ ] **Document results** in `LOAD_TEST.md`: tool used, script summary, hardware, results table (VUs, req/s, p50/p95/p99 latency, error rate)
- [ ] **Justify limits** relative to hardware (e.g. "saturates at ~800 concurrent WebSocket connections on a 4-core 8GB machine due to goroutine memory")

---

### 12. CI / Testing

- [ ] **Unit tests** with Go's built-in `testing` package - test service layer functions (vote logic, license checks, concurrency helpers)
- [ ] **Integration tests** for HTTP handlers - use `net/http/httptest` (built-in) to spin up the router and fire requests without a real server
- [ ] **Mock the DB** in unit tests - define repository interfaces; inject a mock in tests
- [ ] **CI pipeline** with **GitHub Actions**
  - `go test ./...` on every push and PR
  - `go vet ./...` + `staticcheck` for linting
- [ ] **`go.sum` committed** to repo (dependency integrity); `go.mod` defines all deps; `go mod download` in Makefile fetches everything

---

## 📱 MOBILE APP - Flutter + Kotlin + Android SDK

---

### 1. Project Setup

- [ ] **Create Flutter project** targeting Android
  - `flutter create music_room --platforms android`
- [ ] **Use Kotlin** for any Android-native code (platform channels, device info, sensors)
  - Default Android project generated by Flutter already uses Kotlin
- [ ] **Android SDK** configured for debugging (`adb`, emulator or physical device via USB)
- [ ] **Configure base URL as an environment variable**
  - Use `flutter_dotenv` to load a `.env` file; inject `API_BASE_URL` at startup
  - Never hardcode the server address
- [ ] **State management:** use `flutter_riverpod` - minimal boilerplate, scales well, no code generation required
- [ ] **App architecture:** feature-based folder structure
  ```
  /lib
    /features
      /auth
      /profile
      /track_vote
      /delegation
      /playlist_editor
    /core
      /api       → HTTP client, WebSocket client
      /models    → data classes
      /widgets   → shared UI components
  ```

---

### 2. Authentication Screens

- [ ] **Registration screen** - email + password fields, client-side validation (non-empty, valid email format, password min length)
- [ ] **Login screen** - email + password, show error on wrong credentials
- [ ] **Google Sign-In button**
  - Use `google_sign_in` Flutter plugin - gets the OAuth token on the device; send `idToken` to your Go server for verification (server exchanges it with Google's tokeninfo endpoint)
- [ ] **Facebook Login button**
  - Use `flutter_facebook_auth` Flutter plugin - same pattern: get access token on device, send to Go server for verification
- [ ] **Account linking screen** - for a logged-in email user, show buttons to connect Google or Facebook; call the server's account-link endpoint
- [ ] **Post-registration email notice** - screen/banner telling the user to check their email to confirm their account
- [ ] **Forgot password screen** - email input field; calls server endpoint; shows success message
- [ ] **Secure token storage** - store JWT access token and refresh token using `flutter_secure_storage`
  - On Android this uses the Android Keystore via EncryptedSharedPreferences internally
- [ ] **HTTP client with auth interceptor**
  - Use `dio` as the HTTP client
  - Add a `Dio` interceptor that automatically attaches `Authorization: Bearer <token>` to every request and handles 401s by attempting a token refresh before retrying

---

### 3. User Profile

- [ ] **Profile screen** - display and edit all four visibility sections: public, friends-only, private, music preferences
- [ ] **Section-based editing** - each section editable independently; PATCH to the server on save
- [ ] **View other users' profiles** - fetch and display only the fields the server returns (server enforces visibility)
- [ ] **Friends screen** - list friends; show incoming/outgoing requests; accept/reject/unfriend buttons

---

### 4. Service - Music Track Vote (Flutter UI)

- [ ] **Event list screen** - fetch and display public events + invited private events; search bar calling `GET /events?q=...`
- [ ] **Create event screen** - form: name, visibility toggle, pick location (use `geolocator` to get current GPS, display on a simple map or just show coordinates), set vote time window
- [ ] **Event detail screen** - display live queue sorted by vote count; each item shows track name, artist, vote count, and an upvote button
- [ ] **Suggest a track** - open a search bottom sheet, query the Go server's music search proxy, tap to add to queue
- [ ] **Vote button** - single tap sends `POST /events/:id/tracks/:trackId/vote`; optimistically update UI, correct on server response
- [ ] **WebSocket connection** - on entering an event detail screen, open a WS connection to receive live queue updates; update the list on each incoming message
  - Use `web_socket_channel` Flutter package
- [ ] **Invite friends to private event** - friend picker dialog, calls invite endpoint
- [ ] **License/access error UI** - if server returns `403` with a specific code, show a meaningful message ("You are not in the right location", "Voting is closed until 4PM", etc.)

---

### 5. Service - Music Control Delegation (Flutter UI)

- [ ] **My devices screen** - list devices registered to the user's account
- [ ] **Register this device** - on first launch (or from settings), call `POST /devices` with device name/model obtained via Kotlin platform channel using Android's `Build.MODEL` and `Build.MANUFACTURER`
  - Write a small Kotlin `MethodChannel` handler in `MainActivity.kt` to return `Build.MODEL` to Flutter
- [ ] **Delegate control screen** - select a device, then pick a friend from the friend list; call delegate endpoint
- [ ] **Revoke button** - shown next to any device that has an active delegate; calls revoke endpoint
- [ ] **Playback control UI** - when the user owns a device with an active delegate OR has been granted control: show play/pause/skip/volume slider; each action sends a command via the API
- [ ] **WebSocket listener for commands** - the device owner's app subscribes to their device channel; incoming commands (from the delegate) are executed on the local player

---

### 6. Service - Music Playlist Editor (Flutter UI)

- [ ] **Playlist list screen** - public playlists + invited private playlists
- [ ] **Create playlist screen** - name + visibility toggle
- [ ] **Playlist detail screen** - scrollable track list with collaborator avatars; real-time updates via WebSocket
- [ ] **Add track** - search bottom sheet (same music search proxy); tap to append
- [ ] **Remove track** - swipe-to-delete or long-press menu
- [ ] **Reorder tracks** - Flutter's built-in `ReorderableListView` widget; on drop, call the position PATCH endpoint
- [ ] **Real-time updates via WebSocket** - open WS on screen entry; apply incoming `add`, `remove`, `move` events to the local list state
- [ ] **Conflict display** - if a track the user just moved was simultaneously moved by another user, the WS update will overwrite the local state; show a brief snackbar ("Playlist updated by another user")
- [ ] **Invite friends to private playlist** - same friend picker as events
- [ ] **Read-only mode** - if the server returns `403` on any edit action (no edit license), disable all editing widgets; show a "View only" badge

---

### 7. Action Logging (Mobile Side)

- [ ] **Add custom headers to every `dio` request** via a `dio` interceptor:
  - `X-Platform: android`
  - `X-Device-Model: <Build.MODEL>` - fetched once on startup via Kotlin `MethodChannel`
  - `X-App-Version: <versionName>` - read from `package_info_plus` Flutter plugin

---

### 8. General UX & Navigation

- [ ] **Navigation** - use `go_router` for declarative routing; bottom `NavigationBar` with 4 tabs: Track Vote, Delegation, Playlist Editor, Profile
- [ ] **Loading states** - use Riverpod's `AsyncValue` to show `CircularProgressIndicator` while data is loading
- [ ] **Error states** - Riverpod's `AsyncValue.error` mapped to a user-facing `SnackBar` or inline error widget
- [ ] **Empty states** - custom empty state widget (icon + message) for empty lists
- [ ] **Pull-to-refresh** - wrap list screens in `RefreshIndicator`
- [ ] **Form validation** - use Flutter's built-in `Form` + `TextFormField` with `validator` callbacks; show inline error text

---

# PART 2 - BONUS

---

## 🖥️ SERVER - Bonus

---

### B1. Multi-platform Support (Web)

- [ ] **Flutter Web build** compiles the same Flutter app to a web target - no separate server-side work needed beyond ensuring CORS is already configured (it is, from mandatory section)
  - Run `flutter build web`; serve the `build/web` folder as static files from the Go server using `gin`'s `Static()` or `StaticFS()`
- [ ] **Verify OAuth redirect URIs** include the web origin in both Google and Facebook developer consoles

---

### B2. IoT / Beacon Integration

- [ ] **`POST /beacons`** - register a BLE beacon UUID tied to an event
- [ ] **`GET /events/nearby?lat=&lng=&radius=`** - return events whose beacon or location falls within range
- [ ] **Push notification endpoint** - accept a device push token, store it; trigger a notification when a user's device enters a beacon zone
  - Use **Firebase Cloud Messaging (FCM)** HTTP v1 API - call it directly from Go with `net/http`; no Go FCM SDK needed

---

### B3. Free vs. Paid Subscription

- [ ] **Add `subscription_tier` column** (`free` / `premium`) to the `users` table
- [ ] **Feature gate middleware** - `gin` middleware that checks `subscription_tier` for gated endpoints; returns `403` with code `SUBSCRIPTION_REQUIRED` for free users
- [ ] **Mock payment endpoint** - `POST /subscriptions/upgrade` sets `subscription_tier = premium`; no real payment gateway required to meet the spec
- [ ] **Define and document the feature matrix** in `README.md`

---

### B4. Offline Mode (Server-side Sync Support)

- [ ] **`POST /sync`** - accepts an array of offline actions (`{type, payload, client_timestamp}`); processes them in order; returns the diff (new/changed/deleted items since `last_sync_at`)
- [ ] **Soft-delete all records** - add `deleted_at` timestamp column to all main tables; `GET` endpoints filter `WHERE deleted_at IS NULL`
- [ ] **Conflict policy: server-wins** - if a client tries to modify a record that was deleted or updated on the server after `client_timestamp`, the server's version takes precedence; return the resolved state

---

## 📱 MOBILE APP - Bonus

---

### B5. Multi-platform (Web)

- [ ] **Enable Flutter Web target** - `flutter create --platforms web` or add later with `flutter config --enable-web`
- [ ] **Test all screens in Chrome** using `flutter run -d chrome`
- [ ] **Swap `flutter_secure_storage`** for `shared_preferences` on web (secure storage is Android/iOS only); use conditional imports or a storage abstraction layer

---

### B6. IoT / Beacon Detection

- [ ] **BLE beacon scanning** via Kotlin platform channel - use `AltBeacon Android Beacon Library` in the Kotlin layer (`MainActivity.kt`); expose scan results to Flutter via `MethodChannel` or `EventChannel`
- [ ] **On beacon detected**, call `GET /events/nearby` with current GPS; display an in-app notification banner or system notification
  - Use `flutter_local_notifications` for the system notification

---

### B7. Free vs. Paid Subscription (Mobile UI)

- [ ] **Show subscription badge** on profile screen (`Free` / `Premium`)
- [ ] **Paywall bottom sheet** - triggered when a free user taps a premium feature; shows feature list and an "Upgrade" button
- [ ] **Mock upgrade flow** - "Upgrade" button calls `POST /subscriptions/upgrade`; on success, refresh user state via Riverpod; premium features unlock immediately
- [ ] **No real in-app purchase needed** - mock is sufficient per the spec's intent

---

### B8. Offline Mode (Mobile)

- [ ] **Local database** with `drift` (Flutter-native SQLite ORM, pure Dart, formerly Moor)
  - Cache `playlists`, `tracks`, `events`, `queue` tables locally
- [ ] **Offline action queue table** in Drift - each row stores `{action_type, payload_json, created_at}`
- [ ] **Network detection** with `connectivity_plus` Flutter plugin - watch for `ConnectivityResult.none`
- [ ] **Optimistic UI** - apply actions locally to Drift DB immediately; enqueue them for sync
- [ ] **Background sync on reconnect** - when connectivity restores, drain the offline action queue by calling `POST /sync`; update local DB with server response
- [ ] **Conflict snackbar** - display which actions were overridden by the server's conflict resolution

---