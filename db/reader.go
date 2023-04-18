package db

import (
	"context"
)

// Reader is the interface that wraps database queries.
type Reader interface {

	// GetChain gets chain information by chain id.
	GetChain(ctx context.Context, chainId string) (Chain, error)
}

var _ Reader = &dbImpl{}

func (db *dbImpl) GetChain(ctx context.Context, chainId string) (Chain, error) {
	return db.queries.GetChain(ctx, chainId)
}
