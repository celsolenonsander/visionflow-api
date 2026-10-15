package httpapi

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func TestExtractBearerToken(t *testing.T) {
	tests := []struct {
		name   string
		header string
		want   string
	}{
		{"vazio", "", ""},
		{"sem bearer", "abc123", ""},
		{"bearer correto", "Bearer abc123", "abc123"},
		{"bearer case-insensitive", "bearer abc123", "abc123"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// ... monta request com header ...
			// ... chama extractBearerToken ...
			// ... compara com tt.want ...
			_ = tt
		})
	}
}

func TestParseToken(t *testing.T) {
	secret := "test-secret"

	h := &Handler{JWTSecret: secret}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": 42,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	signed, _ := token.SignedString([]byte(secret))

	claims, err := h.parseToken(signed)
	if err != nil {
		t.Fatalf("parseToken erro: %v", err)
	}
	if claims["sub"].(float64) != 42 {
		t.Fatalf("sub errado: %v", claims["sub"])
	}
}
