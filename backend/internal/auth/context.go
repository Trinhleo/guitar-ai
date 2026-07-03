package auth

import (
	"context"
	"errors"
	"net/http"
)

type contextKey string

const userIDKey contextKey = "userID"

var ErrUnauthorized = errors.New("unauthorized")

func WithUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}

func UserIDFromContext(ctx context.Context) (string, bool) {
	userID, ok := ctx.Value(userIDKey).(string)
	return userID, ok && userID != ""
}

func UserIDFromRequest(r *http.Request) (string, error) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		return "", ErrUnauthorized
	}
	return userID, nil
}
