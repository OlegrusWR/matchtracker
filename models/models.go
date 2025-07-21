package models

import (
	"database/sql"
	"time"
)

type Team struct {
	ID          int64     `json:"id"`
	ExternalID  string    `json:"external_id"`
	Name        string    `json:"name"`
	Tag         string    `json:"tag"`
	CountryCode string    `json:"country_code"`
	LogoURL     string    `json:"logo_url"`
	Ranking     int       `json:"ranking"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Player struct {
	ID          int64     `json:"id"`
	TeamID      *int64    `json:"team_id"`
	ExternalID  string    `json:"external_id"`
	Username    string    `json:"username"`
	RealName    string    `json:"real_name"`
	CountryCode string    `json:"country_code"`
	RankTier    int       `json:"rank_tier"`
	Rating      float64   `json:"rating"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Tournament struct {
	ID         int64     `json:"id"`
	ExternalID string    `json:"external_id"`
	Name       string    `json:"name"`
	Tier       string    `json:"tier"`
	PrizePool  int       `json:"prize_pool"`
	Currency   string    `json:"currency"`
	StartDate  time.Time `json:"start_date"`
	EndDate    time.Time `json:"end_date"`
	Location   string    `json:"location"`
	Status     string    `json:"status"`
	CreatedAt  time.Time `json:"created_at"`
}

type Match struct {
	ID               int64      `json:"id"`
	TournamentID     *int64     `json:"tournament_id"`
	ExternalMatchID  string     `json:"external_match_id"`
	Team1ID          *int64     `json:"team1_id"`
	Team2ID          *int64     `json:"team2_id"`
	StartTime        time.Time  `json:"start_time"`
	EndTime          *time.Time `json:"end_time"`
	DurationSeconds  *int       `json:"duration_seconds"`
	Format           string     `json:"format"`
	WinnerTeamID     *int64     `json:"winner_team_id"`
	Team1Score       int        `json:"team1_score"`
	Team2Score       int        `json:"team2_score"`
	Status           string     `json:"status"`
	Stage            string     `json:"stage"`
	CreatedAt        time.Time  `json:"created_at"`
	
	Team1      *Team       `json:"team1,omitempty"`
	Team2      *Team       `json:"team2,omitempty"`
	Tournament *Tournament `json:"tournament,omitempty"`
	WinnerTeam *Team       `json:"winner_team,omitempty"`
	Maps       []*MatchMap `json:"maps,omitempty"`
}

type MatchMap struct {
	ID            int64  `json:"id"`
	MatchID       int64  `json:"match_id"`
	MapName       string `json:"map_name"`
	MapOrder      int    `json:"map_order"`
	Team1Score    int    `json:"team1_score"`
	Team2Score    int    `json:"team2_score"`
	WinnerTeamID  *int64 `json:"winner_team_id"`
	DurationSeconds *int `json:"duration_seconds"`
	Status        string `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	
	Match      *Match `json:"match,omitempty"`
	WinnerTeam *Team  `json:"winner_team,omitempty"`
}

type MatchPlayer struct {
	ID        int64   `json:"id"`
	MatchID   int64   `json:"match_id"`
	MapID     *int64  `json:"map_id"`
	PlayerID  int64   `json:"player_id"`
	TeamID    int64   `json:"team_id"`
	Kills     int     `json:"kills"`
	Deaths    int     `json:"deaths"`
	Assists   int     `json:"assists"`
	Headshots int     `json:"headshots"`
	MVPs      int     `json:"mvps"`
	Score     int     `json:"score"`
	ADR       float64 `json:"adr"`
	Rating    float64 `json:"rating"`
	CreatedAt time.Time `json:"created_at"`
	
	Match  *Match  `json:"match,omitempty"`
	Map    *MatchMap `json:"map,omitempty"`
	Player *Player `json:"player,omitempty"`
	Team   *Team   `json:"team,omitempty"`
}

type Subscription struct {
	ID               int64     `json:"id"`
	UserID           string    `json:"user_id"`
	Platform         string    `json:"platform"`
	ChatID           string    `json:"chat_id"`
	TeamID           *int64    `json:"team_id"`
	TournamentID     *int64    `json:"tournament_id"`
	PlayerID         *int64    `json:"player_id"`
	NotificationType string    `json:"notification_type"`
	IsActive         bool      `json:"is_active"`
	CreatedAt        time.Time `json:"created_at"`
	
	Team       *Team       `json:"team,omitempty"`
	Tournament *Tournament `json:"tournament,omitempty"`
	Player     *Player     `json:"player,omitempty"`
}

type PlayerStats struct {
	ID              int64     `json:"id"`
	PlayerID        int64     `json:"player_id"`
	TeamID          *int64    `json:"team_id"`
	MatchesPlayed   int       `json:"matches_played"`
	Wins            int       `json:"wins"`
	Losses          int       `json:"losses"`
	TotalKills      int       `json:"total_kills"`
	TotalDeaths     int       `json:"total_deaths"`
	TotalAssists    int       `json:"total_assists"`
	TotalHeadshots  int       `json:"total_headshots"`
	TotalMVPs       int       `json:"total_mvps"`
	AvgKD           float64   `json:"avg_kd"`
	AvgADR          float64   `json:"avg_adr"`
	AvgRating       float64   `json:"avg_rating"`
	Winrate         float64   `json:"winrate"`
	LastMatchTime   *time.Time `json:"last_match_time"`
	UpdatedAt       time.Time `json:"updated_at"`
	
	Player *Player `json:"player,omitempty"`
	Team   *Team   `json:"team,omitempty"`
}

type TeamStats struct {
	ID             int64     `json:"id"`
	TeamID         int64     `json:"team_id"`
	MatchesPlayed  int       `json:"matches_played"`
	Wins           int       `json:"wins"`
	Losses         int       `json:"losses"`
	Winrate        float64   `json:"winrate"`
	MapsWon        int       `json:"maps_won"`
	MapsLost       int       `json:"maps_lost"`
	MapWinrate     float64   `json:"map_winrate"`
	LastMatchTime  *time.Time `json:"last_match_time"`
	UpdatedAt      time.Time `json:"updated_at"`
	
	Team *Team `json:"team,omitempty"`
}

type CreateMatchRequest struct {
	TournamentID    *int64    `json:"tournament_id"`
	ExternalMatchID string    `json:"external_match_id"`
	Team1ID         *int64    `json:"team1_id"`
	Team2ID         *int64    `json:"team2_id"`
	StartTime       time.Time `json:"start_time"`
	Format          string    `json:"format"`
	Stage           string    `json:"stage"`
}

type CreateTeamRequest struct {
	ExternalID  string `json:"external_id"`
	Name        string `json:"name"`
	Tag         string `json:"tag"`
	CountryCode string `json:"country_code"`
	LogoURL     string `json:"logo_url"`
	Ranking     int    `json:"ranking"`
}

type CreatePlayerRequest struct {
	TeamID      *int64  `json:"team_id"`
	ExternalID  string  `json:"external_id"`
	Username    string  `json:"username"`
	RealName    string  `json:"real_name"`
	CountryCode string  `json:"country_code"`
	RankTier    int     `json:"rank_tier"`
	Rating      float64 `json:"rating"`
}

type CreateTournamentRequest struct {
	ExternalID string    `json:"external_id"`
	Name       string    `json:"name"`
	Tier       string    `json:"tier"`
	PrizePool  int       `json:"prize_pool"`
	Currency   string    `json:"currency"`
	StartDate  time.Time `json:"start_date"`
	EndDate    time.Time `json:"end_date"`
	Location   string    `json:"location"`
	Status     string    `json:"status"`
}

var NotificationTypes = struct {
	MatchStart    string
	MatchEnd      string
	TeamUpdate    string
	PlayerUpdate  string
	TournamentStart string
}{
	MatchStart:      "match_start",
	MatchEnd:        "match_end",
	TeamUpdate:      "team_update",
	PlayerUpdate:    "player_update",
	TournamentStart: "tournament_start",
}

var MatchStatuses = struct {
	Scheduled string
	Live      string
	Finished  string
	Cancelled string
	Postponed string
}{
	Scheduled: "scheduled",
	Live:      "live",
	Finished:  "finished",
	Cancelled: "cancelled",
	Postponed: "postponed",
}

var TournamentStatuses = struct {
	Upcoming string
	Active   string
	Finished string
}{
	Upcoming: "upcoming",
	Active:   "active",
	Finished: "finished",
}

var Platforms = struct {
	Telegram string
	Discord  string
}{
	Telegram: "telegram",
	Discord:  "discord",
}

var MapStatuses = struct {
	Upcoming string
	Live     string
	Finished string
}{
	Upcoming: "upcoming",
	Live:     "live",
	Finished: "finished",
}

// Helper methods для работы с nullable полями

// NullInt64 для работы с nullable int64
func NullInt64(i *int64) sql.NullInt64 {
	if i == nil {
		return sql.NullInt64{Valid: false}
	}
	return sql.NullInt64{Int64: *i, Valid: true}
}

// NullString для работы с nullable string
func NullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{Valid: false}
	}
	return sql.NullString{String: *s, Valid: true}
}

// NullTime для работы с nullable time
func NullTime(t *time.Time) sql.NullTime {
	if t == nil {
		return sql.NullTime{Valid: false}
	}
	return sql.NullTime{Time: *t, Valid: true}
}

// Int64Ptr возвращает указатель на int64
func Int64Ptr(i int64) *int64 {
	return &i
}

// StringPtr возвращает указатель на string
func StringPtr(s string) *string {
	return &s
}

// TimePtr возвращает указатель на time.Time
func TimePtr(t time.Time) *time.Time {
	return &t
}