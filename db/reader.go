package db

import (
	"context"
	"encoding/json"
	"fmt"
)

// Reader is the interface that wraps database queries.
type Reader interface {

	// GetChain gets chain information by chain id.
	GetChain(ctx context.Context, chainId string) (Chain, error)

	// GetChainMsgs gets messages by chain number.
	GetChainMsgs(ctx context.Context, chainId string) ([]Msg, error)

	// GetChainMsgsByType gets messages by chain number.
	GetChainMsgsByType(ctx context.Context, chainId string, typeUrl string) ([]Msg, error)
}

var _ Reader = &dbImpl{}

func (db *dbImpl) GetChain(ctx context.Context, chainId string) (Chain, error) {
	return db.queries.GetChain(ctx, chainId)
}

func (db *dbImpl) GetChainMsgs(ctx context.Context, chainId string) ([]Msg, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgs(ctx, chain.Num)
}

func (db *dbImpl) GetChainMsgsByType(ctx context.Context, chainId string, typeUrl string) ([]Msg, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgsByType(ctx, GetChainMsgsByTypeParams{
		ChainNum: chain.Num,
		Data:     json.RawMessage(fmt.Sprintf(`/%s`, typeUrl)),
	})
}
