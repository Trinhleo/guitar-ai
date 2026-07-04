package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Trinhleo/guitar-ai/backend/internal/config"
	"github.com/Trinhleo/guitar-ai/backend/internal/models"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrInvalidToken       = errors.New("invalid token")
)

type Service struct {
	pool   *pgxpool.Pool
	secret []byte
	expiry time.Duration
}

type Claims struct {
	UserID string `json:"sub"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

func NewService(pool *pgxpool.Pool, cfg config.Config) *Service {
	return &Service{
		pool:   pool,
		secret: []byte(cfg.JWTSecret),
		expiry: cfg.JWTExpiry,
	}
}

func (s *Service) Register(ctx context.Context, req models.RegisterRequest) (models.AuthResponse, error) {
	email := strings.TrimSpace(strings.ToLower(req.Email))
	if email == "" || len(req.Password) < 8 {
		return models.AuthResponse{}, fmt.Errorf("invalid registration input")
	}

	passwordHash, err := HashPassword(req.Password)
	if err != nil {
		return models.AuthResponse{}, err
	}

	userID := uuid.NewString()
	_, err = s.pool.Exec(ctx, `
		INSERT INTO users (id, email, password_hash, display_name)
		VALUES ($1, $2, $3, $4)`,
		userID, email, passwordHash, strings.TrimSpace(req.DisplayName),
	)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique") {
			return models.AuthResponse{}, ErrEmailTaken
		}
		return models.AuthResponse{}, err
	}

	token, err := s.generateToken(userID, email)
	if err != nil {
		return models.AuthResponse{}, err
	}

	return models.AuthResponse{Token: token, UserID: userID, Email: email}, nil
}

func (s *Service) Login(ctx context.Context, req models.LoginRequest) (models.AuthResponse, error) {
	email := strings.TrimSpace(strings.ToLower(req.Email))
	if email == "" || req.Password == "" {
		return models.AuthResponse{}, ErrInvalidCredentials
	}

	var userID, passwordHash string
	err := s.pool.QueryRow(ctx, `
		SELECT id, password_hash FROM users WHERE email = $1`, email).
		Scan(&userID, &passwordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.AuthResponse{}, ErrInvalidCredentials
	}
	if err != nil {
		return models.AuthResponse{}, err
	}

	if !CheckPassword(req.Password, passwordHash) {
		return models.AuthResponse{}, ErrInvalidCredentials
	}

	token, err := s.generateToken(userID, email)
	if err != nil {
		return models.AuthResponse{}, err
	}

	return models.AuthResponse{Token: token, UserID: userID, Email: email}, nil
}

func (s *Service) ValidateToken(tokenString string) (Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, ErrInvalidToken
		}
		return s.secret, nil
	})
	if err != nil {
		return Claims{}, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid || claims.UserID == "" {
		return Claims{}, ErrInvalidToken
	}
	return *claims, nil
}

func (s *Service) generateToken(userID, email string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.expiry)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}
