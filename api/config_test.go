package api

import (
	"fmt"
	"os"
	"testing"

	"gotest.tools/assert"
)

func TestConfig(t *testing.T) {
	port := uint64(3030)
	allowedOrigins := "foo.bar"
	databaseUrl := "foobar"

	assert.NilError(t, os.Setenv("PORT", fmt.Sprintf("%d", port)))
	assert.NilError(t, os.Setenv("ALLOWED_ORIGINS", allowedOrigins))
	assert.NilError(t, os.Setenv("DATABASE_URL", databaseUrl))

	cfg := LoadConfig()

	assert.Equal(t, port, cfg.Port)
	assert.Equal(t, allowedOrigins, cfg.AllowedOrigins)
	assert.Equal(t, databaseUrl, cfg.DatabaseURL)
}
