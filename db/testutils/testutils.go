package testutils

import (
	"database/sql"
	"fmt"
	"io"
	"testing"

	epg "github.com/fergusstrange/embedded-postgres"
	"github.com/phayes/freeport"
	"github.com/rs/zerolog"
	"github.com/stretchr/testify/require"

	"github.com/regen-network/analytics/db"
)

const verbose = false

// NewTestDB creates a postgres database handle for testing purposes.
func NewTestDB(t *testing.T) *sql.DB {
	port, err := freeport.GetFreePort()
	require.NoError(t, err)
	var logger zerolog.Logger
	if verbose {
		logger = zerolog.New(zerolog.NewConsoleWriter())
	} else {
		logger = zerolog.New(io.Discard)
	}
	cfg := epg.DefaultConfig().
		Port(uint32(port)).
		Database("postgres").
		Logger(logger).
		RuntimePath(t.TempDir())
	postgres := epg.NewDatabase(cfg)
	require.NoError(t, postgres.Start())
	t.Cleanup(func() {
		require.NoError(t, postgres.Stop())
	})
	sqlDb, err := db.Open(
		fmt.Sprintf("host=localhost port=%d user=postgres password=postgres dbname=postgres sslmode=disable", port),
		logger,
	)
	require.NoError(t, err)
	return sqlDb
}

// NewTestDatabase creates an embedded postgres database for testing purposes.
func NewTestDatabase(t *testing.T) db.Database {
	return db.NewDatabase(NewTestDB(t))
}
