package api

import (
	"context"
	"fmt"
	"testing"

	"github.com/phayes/freeport"
	"github.com/rs/zerolog"
	"gotest.tools/assert"

	"github.com/regen-network/analytics/db"
	"github.com/regen-network/analytics/db/testutils"
)

type TestSuite struct {
	ctx context.Context
	app *App
	url string
	db  db.Database
}

func setupSuite(t *testing.T) *TestSuite {
	ts := TestSuite{ctx: context.Background()}
	logger := zerolog.New(zerolog.NewConsoleWriter())
	ts.db = testutils.NewTestDatabase(t)
	ts.app = Initialize(LoadConfig(), ts.db, logger)
	port, err := freeport.GetFreePort()
	assert.NilError(t, err)
	ts.url = fmt.Sprintf("http://localhost:%d", port)
	go ts.app.Run(fmt.Sprintf(":%d", port))
	return &ts
}

func TestApp_GetChain(t *testing.T) {
	//s := setupSuite(t)
}
