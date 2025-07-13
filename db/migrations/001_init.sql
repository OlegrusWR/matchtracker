CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE IF NOT EXISTS games (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL  UNIQUE,
    api_endpoint VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
)

CREATE TABLE IF NOT EXISTS players (
    id BIGSERIAL PRIMARY KEY,
    game_id INTEGER REFERENCES games(id),
    external_id VARCHAR(255) NOT NULL,
    username VARCHAR(50),
    rank_tier INTEGER,
    mmr INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    update_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    UNIQUE(game_id, external_id)
)

CREATE TABLE IF NOT EXISTS matches (
    id BIGSERIAL PRIMARY KEY,
    game_id INTEGER REFERENCES games(id),
    external_match_id VARCHAR(255) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_seconds INTEGER,
    game_mode VARCHAR(50),
    winner_team INTEGER,
    radiant_win BOOLEAN,
    status VARCHAR(20) DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(game_id, external_match_id)
)

SELECT create_hypertable('matches', 'start_time', if_not_exists => TRUE)

