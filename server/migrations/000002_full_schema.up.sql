-- 1. Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    subscription_tier VARCHAR(50) DEFAULT 'free' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. User Providers table (for OAuth Google/Facebook)
CREATE TABLE IF NOT EXISTS user_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (provider, provider_id)
);
CREATE INDEX IF NOT EXISTS idx_user_providers_user_id ON user_providers(user_id);

-- 3. Refresh Tokens table (session management)
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);

-- 4. Friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_friendships_no_self_friend CHECK (requester_id <> addressee_id),
    UNIQUE (requester_id, addressee_id)
);
CREATE INDEX IF NOT EXISTS idx_friendships_requester_id ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee_id ON friendships(addressee_id);

-- 5. Events table (Music Track Vote)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius DOUBLE PRECISION,
    vote_start TIMESTAMP WITH TIME ZONE,
    vote_end TIMESTAMP WITH TIME ZONE,
    license INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_events_owner_id ON events(owner_id);

-- 6. Event Invites table
CREATE TABLE IF NOT EXISTS event_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (event_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_event_invites_event_id ON event_invites(event_id);
CREATE INDEX IF NOT EXISTS idx_event_invites_user_id ON event_invites(user_id);

-- 7. Tracks table (Event Queue suggestion)
CREATE TABLE IF NOT EXISTS tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    external_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    suggested_by UUID REFERENCES users(id) ON DELETE SET NULL,
    vote_count INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (event_id, external_id)
);
CREATE INDEX IF NOT EXISTS idx_tracks_event_id ON tracks(event_id);
CREATE INDEX IF NOT EXISTS idx_tracks_suggested_by ON tracks(suggested_by);

-- 8. Votes table
CREATE TABLE IF NOT EXISTS votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (track_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_votes_track_id ON votes(track_id);
CREATE INDEX IF NOT EXISTS idx_votes_user_id ON votes(user_id);

-- 9. Devices table (Music Control Delegation)
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    model VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);

-- 10. Delegations table
CREATE TABLE IF NOT EXISTS delegations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    delegate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_delegations_no_self_delegate CHECK (owner_id <> delegate_id)
);
CREATE INDEX IF NOT EXISTS idx_delegations_device_id ON delegations(device_id);
CREATE INDEX IF NOT EXISTS idx_delegations_owner_id ON delegations(owner_id);
CREATE INDEX IF NOT EXISTS idx_delegations_delegate_id ON delegations(delegate_id);

-- 11. Playlists table (Music Playlist Editor)
CREATE TABLE IF NOT EXISTS playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    visibility VARCHAR(50) DEFAULT 'public' NOT NULL,
    license INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_playlists_owner_id ON playlists(owner_id);

-- 12. Playlist Invites table
CREATE TABLE IF NOT EXISTS playlist_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (playlist_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_playlist_invites_playlist_id ON playlist_invites(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_invites_user_id ON playlist_invites(user_id);

-- 13. Playlist Tracks table
CREATE TABLE IF NOT EXISTS playlist_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    playlist_id UUID NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    external_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    position INTEGER NOT NULL,
    added_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (playlist_id, external_id)
);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist_id ON playlist_tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_added_by ON playlist_tracks(added_by);
