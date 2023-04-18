package db

import (
	"database/sql"
	"io"

	"github.com/lib/pq"
	"github.com/rs/zerolog"
	sqllog "github.com/simukti/sqldb-logger"
	"github.com/simukti/sqldb-logger/logadapter/zerologadapter"
)

// Open opens a database connection.
func Open(postgresUrl string, logger zerolog.Logger) (*sql.DB, error) {
	loggerAdapter := zerologadapter.New(logger)
	sqlDb := sqllog.OpenDriver(
		postgresUrl,
		pq.Driver{},
		loggerAdapter,
		sqllog.WithQueryerLevel(sqllog.LevelDebug),
		sqllog.WithExecerLevel(sqllog.LevelDebug),
		sqllog.WithPreparerLevel(sqllog.LevelDebug),
	)

	err := sqlDb.Ping()
	if err != nil {
		return nil, err
	}

	return sqlDb, nil
}

// Database defines an interface for database reads.
type Database interface {
	Reader
	io.Closer
}

type dbImpl struct {
	db      *sql.DB
	queries *Queries
}

// NewDatabase returns a new Database.
func NewDatabase(db *sql.DB) Database {
	return &dbImpl{db: db, queries: New(db)}
}

// Close closes the underlying sql.DB.
func (db *dbImpl) Close() error {
	return db.db.Close()
}
