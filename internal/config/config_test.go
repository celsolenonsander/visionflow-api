package config

import (
	"net/url"
	"testing"
)

func TestDSNEscapesCredentialsAndUsesConfiguredSSLMode(t *testing.T) {
	config := Config{
		DBHost:     "db.internal",
		DBPort:     "5432",
		DBUser:     "api user",
		DBPassword: "p@ss:/?#%word",
		DBName:     "vision flow",
		DBSSLMode:  "require",
	}

	parsed, err := url.Parse(config.DSN())
	if err != nil {
		t.Fatalf("parse DSN: %v", err)
	}
	password, hasPassword := parsed.User.Password()
	if parsed.User.Username() != config.DBUser || !hasPassword || password != config.DBPassword {
		t.Fatal("DSN did not preserve escaped credentials")
	}
	if parsed.Host != "db.internal:5432" || parsed.Path != "/vision flow" {
		t.Fatalf("DSN host/path = %q/%q, want db.internal:5432 and /vision flow", parsed.Host, parsed.Path)
	}
	if got := parsed.Query().Get("sslmode"); got != "require" {
		t.Fatalf("DSN sslmode = %q, want require", got)
	}
}
