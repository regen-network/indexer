package db_test

import (
	"context"
	"testing"

	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/stretchr/testify/suite"

	"github.com/regen-network/analytics/db"
	"github.com/regen-network/analytics/db/testutils"
)

type testSuite struct {
	suite.Suite
	db  db.Database
	ctx context.Context
}

func TestSuite(t *testing.T) {
	suite.Run(t, &testSuite{})
}

func (s *testSuite) SetupSuite() {
	s.ctx = context.Background()
	s.db = testutils.NewTestDatabase(s.T())
}

// reset database to avoid clobbering data
func (s *testSuite) SetupTest() {
	s.db = testutils.NewTestDatabase(s.T())
}

func (s *testSuite) TestGetChain() {
	// TODO
}
