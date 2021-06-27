package main

import (
	"context"
	"github.com/jackc/pgx/v4"
	"os"
)

func connect() (*pgx.Conn, error) {
	return pgx.Connect(context.Background(), os.Getenv("DATABASE_URL"))
}

func indexBlock(height uint64, conn *pgx.Conn) {
	//res := types.Result{}
}

type BlockIndexer struct {
	Name    string
	Indexer func(height uint64)
}

