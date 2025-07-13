CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE IF NOT EXISTS teams (
    id BIGSERIAL PRIMARY KEY,
    external_id VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(30) NOT NULL,
    tag VARCHAR(20),
    country_code(3),
    logo_url VARCHAR(255),
    rankling INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS players (
    id BIGSERIAL PRIMARY KEY,
    team_id BIGINT REFERENCES teams(id),
    external_id VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100),
    real_name VARCHAR(100),
    country_code VARCHAR(3),
    rank_tier INTEGER,
    rating DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tournaments (
    id BIGSERIAL PRIMARY KEY,
    external_id VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    tier VARCHAR(20), 
    prize_pool INTEGER,
    currency VARCHAR(3) DEFAULT 'USD',
    start_date DATE,
    end_date DATE,
    location VARCHAR(100),
    status VARCHAR(20) DEFAULT 'upcoming', 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS matches (
    id BIGSERIAL PRIMARY KEY,
    tournament_id BIGINT REFERENCES tournaments(id),
    external_match_id VARCHAR(255) NOT NULL UNIQUE,
    team1_id BIGINT REFERENCES teams(id),
    team2_id BIGINT REFERENCES teams(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_seconds INTEGER,
    format VARCHAR(20),
    winner_team_id BIGINT REFERENCES teams(id),
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'scheduled', 
    stage VARCHAR(50), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS match_maps (
    id BIGSERIAL PRIMARY KEY,
    match_id BIGINT REFERENCES matches(id) ON DELETE CASCADE,
    map_name VARCHAR(50) NOT NULL,
    map_order INTEGER NOT NULL,
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    winner_team_id BIGINT REFERENCES teams(id),
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'not_started',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT create_hypertable('matches', 'start_time', if_not_exists => TRUE);

CREATE TABLE IF NOT EXISTS match_players (
    id BIGSERIAL PRIMARY KEY,
    match_id BIGINT REFERENCES matches(id) ON DELETE CASCADE,
    map_id BIGINT REFERENCES match_maps(id) ON DELETE CASCADE,
    player_id BIGINT REFERENCES players(id),
    team_id BIGINT REFERENCES teams(id),
    kills INTEGER DEFAULT 0,
    deaths INTEGER DEFAULT 0,
    assists INTEGER DEFAULT 0,
    headshots INTEGER DEFAULT 0,
    mvps INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    adr DECIMAL(5,2) DEFAULT 0, 
    rating DECIMAL(4,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_stats (
    id BIGSERIAL PRIMARY KEY,
    player_id BIGINT REFERENCES players(id),
    team_id BIGINT REFERENCES teams(id),
    matches_played INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    total_kills INTEGER DEFAULT 0,
    total_deaths INTEGER DEFAULT 0,
    total_assists INTEGER DEFAULT 0,
    total_headshots INTEGER DEFAULT 0,
    total_mvps INTEGER DEFAULT 0,
    avg_kd DECIMAL(4,2) DEFAULT 0,
    avg_adr DECIMAL(5,2) DEFAULT 0,
    avg_rating DECIMAL(4,2) DEFAULT 0,
    winrate DECIMAL(5,2) DEFAULT 0,
    last_match_time TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id)
);

CREATE TABLE IF NOT EXISTS team_stats (
    id BIGSERIAL PRIMARY KEY,
    team_id BIGINT REFERENCES teams(id),
    matches_played INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    winrate DECIMAL(5,2) DEFAULT 0,
    maps_won INTEGER DEFAULT 0,
    maps_lost INTEGER DEFAULT 0,
    map_winrate DECIMAL(5,2) DEFAULT 0,
    last_match_time TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id)
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    chat_id VARCHAR(255) NOT NULL,
    team_id BIGINT REFERENCES teams(id),
    tournament_id BIGINT REFERENCES tournaments(id),
    player_id BIGINT REFERENCES players(id),
    notification_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, platform, chat_id, team_id, tournament_id, player_id, notification_type)
);

CREATE TABLE IF NOT EXISTS api_logs (
    id BIGSERIAL PRIMARY KEY,
    service VARCHAR(50) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    response_time_ms INTEGER,
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT create_hypertable('api_logs', 'timestamp', if_not_exists => TRUE);


CREATE TABLE IF NOT EXISTS predictions (
    id BIGSERIAL PRIMARY KEY,
    match_id BIGINT REFERENCES matches(id),
    model_name VARCHAR(100) NOT NULL,
    predicted_winner_team_id BIGINT REFERENCES teams(id),
    confidence DECIMAL(5,2),
    features JSONB,
    actual_winner_team_id BIGINT REFERENCES teams(id),
    is_correct BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_matches_tournament_id ON matches(tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_start_time ON matches(start_time);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_teams ON matches(team1_id, team2_id);
CREATE INDEX IF NOT EXISTS idx_match_maps_match_id ON match_maps(match_id);
CREATE INDEX IF NOT EXISTS idx_match_players_match_id ON match_players(match_id);
CREATE INDEX IF NOT EXISTS idx_match_players_player_id ON match_players(player_id);
CREATE INDEX IF NOT EXISTS idx_match_players_team_id ON match_players(team_id);
CREATE INDEX IF NOT EXISTS idx_players_team_id ON players(team_id);
CREATE INDEX IF NOT EXISTS idx_players_external_id ON players(external_id);
CREATE INDEX IF NOT EXISTS idx_teams_external_id ON teams(external_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_external_id ON tournaments(external_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON subscriptions(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_api_logs_timestamp ON api_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_api_logs_service ON api_logs(service);

CREATE OR REPLACE FUNCTION update_player_stats(p_player_id BIGINT) 
RETURNS VOID AS $$
DECLARE
    stats_record RECORD;
BEGIN
    SELECT 
        COUNT(*) as matches_played,
        SUM(CASE WHEN mp.team_id = m.winner_team_id THEN 1 ELSE 0 END) as wins,
        SUM(CASE WHEN mp.team_id != m.winner_team_id THEN 1 ELSE 0 END) as losses,
        SUM(mp.kills) as total_kills,
        SUM(mp.deaths) as total_deaths,
        SUM(mp.assists) as total_assists,
        SUM(mp.headshots) as total_headshots,
        SUM(mp.mvps) as total_mvps,
        AVG(mp.adr) as avg_adr,
        AVG(mp.rating) as avg_rating,
        MAX(m.start_time) as last_match_time
    INTO stats_record
    FROM match_players mp
    JOIN matches m ON mp.match_id = m.id
    WHERE mp.player_id = p_player_id AND m.status = 'finished';

    INSERT INTO player_stats (
        player_id, team_id, matches_played, wins, losses, 
        total_kills, total_deaths, total_assists, total_headshots, total_mvps,
        avg_kd, avg_adr, avg_rating, winrate, last_match_time, updated_at
    ) 
    SELECT 
        p_player_id, 
        p.team_id,
        COALESCE(stats_record.matches_played, 0),
        COALESCE(stats_record.wins, 0),
        COALESCE(stats_record.losses, 0),
        COALESCE(stats_record.total_kills, 0),
        COALESCE(stats_record.total_deaths, 0),
        COALESCE(stats_record.total_assists, 0),
        COALESCE(stats_record.total_headshots, 0),
        COALESCE(stats_record.total_mvps, 0),
        CASE 
            WHEN COALESCE(stats_record.total_deaths, 0) > 0 
            THEN ROUND(COALESCE(stats_record.total_kills, 0)::DECIMAL / stats_record.total_deaths, 2)
            ELSE COALESCE(stats_record.total_kills, 0)
        END,
        COALESCE(stats_record.avg_adr, 0),
        COALESCE(stats_record.avg_rating, 0),
        CASE 
            WHEN COALESCE(stats_record.matches_played, 0) > 0 
            THEN ROUND((COALESCE(stats_record.wins, 0)::DECIMAL / stats_record.matches_played) * 100, 2)
            ELSE 0
        END,
        stats_record.last_match_time,
        CURRENT_TIMESTAMP
    FROM players p
    WHERE p.id = p_player_id
    ON CONFLICT (player_id) DO UPDATE SET
        team_id = EXCLUDED.team_id,
        matches_played = EXCLUDED.matches_played,
        wins = EXCLUDED.wins,
        losses = EXCLUDED.losses,
        total_kills = EXCLUDED.total_kills,
        total_deaths = EXCLUDED.total_deaths,
        total_assists = EXCLUDED.total_assists,
        total_headshots = EXCLUDED.total_headshots,
        total_mvps = EXCLUDED.total_mvps,
        avg_kd = EXCLUDED.avg_kd,
        avg_adr = EXCLUDED.avg_adr,
        avg_rating = EXCLUDED.avg_rating,
        winrate = EXCLUDED.winrate,
        last_match_time = EXCLUDED.last_match_time,
        updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_team_stats(p_team_id BIGINT) 
RETURNS VOID AS $$
DECLARE
    stats_record RECORD;
BEGIN
    SELECT 
        COUNT(*) as matches_played,
        SUM(CASE WHEN winner_team_id = p_team_id THEN 1 ELSE 0 END) as wins,
        SUM(CASE WHEN winner_team_id != p_team_id THEN 1 ELSE 0 END) as losses,
        MAX(start_time) as last_match_time
    INTO stats_record
    FROM matches
    WHERE (team1_id = p_team_id OR team2_id = p_team_id) AND status = 'finished';

    -- Статистика по картам
    WITH map_stats AS (
        SELECT 
            SUM(CASE WHEN winner_team_id = p_team_id THEN 1 ELSE 0 END) as maps_won,
            SUM(CASE WHEN winner_team_id != p_team_id THEN 1 ELSE 0 END) as maps_lost
        FROM match_maps mm
        JOIN matches m ON mm.match_id = m.id
        WHERE (m.team1_id = p_team_id OR m.team2_id = p_team_id) AND mm.status = 'finished'
    )
    INSERT INTO team_stats (
        team_id, matches_played, wins, losses, winrate, 
        maps_won, maps_lost, map_winrate, last_match_time, updated_at
    ) 
    SELECT 
        p_team_id,
        COALESCE(stats_record.matches_played, 0),
        COALESCE(stats_record.wins, 0),
        COALESCE(stats_record.losses, 0),
        CASE 
            WHEN COALESCE(stats_record.matches_played, 0) > 0 
            THEN ROUND((COALESCE(stats_record.wins, 0)::DECIMAL / stats_record.matches_played) * 100, 2)
            ELSE 0
        END,
        COALESCE(ms.maps_won, 0),
        COALESCE(ms.maps_lost, 0),
        CASE 
            WHEN COALESCE(ms.maps_won, 0) + COALESCE(ms.maps_lost, 0) > 0 
            THEN ROUND((COALESCE(ms.maps_won, 0)::DECIMAL / (ms.maps_won + ms.maps_lost)) * 100, 2)
            ELSE 0
        END,
        stats_record.last_match_time,
        CURRENT_TIMESTAMP
    FROM map_stats ms
    ON CONFLICT (team_id) DO UPDATE SET
        matches_played = EXCLUDED.matches_played,
        wins = EXCLUDED.wins,
        losses = EXCLUDED.losses,
        winrate = EXCLUDED.winrate,
        maps_won = EXCLUDED.maps_won,
        maps_lost = EXCLUDED.maps_lost,
        map_winrate = EXCLUDED.map_winrate,
        last_match_time = EXCLUDED.last_match_time,
        updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_update_stats() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'finished' AND OLD.status != 'finished' THEN
        PERFORM update_team_stats(NEW.team1_id);
        PERFORM update_team_stats(NEW.team2_id);
        
        PERFORM update_player_stats(mp.player_id)
        FROM match_players mp 
        WHERE mp.match_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stats_on_match_finish
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_stats();

SELECT add_retention_policy('matches', INTERVAL '6 months');
SELECT add_retention_policy('api_logs', INTERVAL '1 month');