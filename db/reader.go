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

	// GetChainMsgs gets messages by chain id.
	GetChainMsgs(ctx context.Context, chainId string) ([]Msg, error)

	// GetChainMsgsByType gets messages by chain id.
	GetChainMsgsByType(ctx context.Context, chainId string, typeUrl string) ([]Msg, error)

	// GetChainEvents gets events by chain id.
	GetChainEvents(ctx context.Context, chainId string) ([]MsgEvent, error)

	// GetChainEventsByType gets events by chain id.
	GetChainEventsByType(ctx context.Context, chainId string, typeUrl string) ([]MsgEvent, error)

	// GetChainEventAttrs gets event attributes by event.
	GetChainEventAttrs(ctx context.Context, event MsgEvent) ([]MsgEventAttr, error)

	// GetChainMsgSubmitProposalByPolicy gets submit proposal messages by chain id and policy address.
	GetChainMsgSubmitProposalByPolicy(ctx context.Context, chainId string, policy string) ([]Msg, error)

	// GetChainMsgEventSubmitProposalByMsg gets submit proposal event by message.
	GetChainMsgEventSubmitProposalByMsg(ctx context.Context, msg Msg) ([]MsgEvent, error)

	// GetChainMsgExecByProposal gets exec proposal messages by chain id and proposal id.
	GetChainMsgExecByProposal(ctx context.Context, chainId string, proposal string) ([]Msg, error)

	// GetChainMsgEventExecByMsg gets exec events by message.
	GetChainMsgEventExecByMsg(ctx context.Context, msg Msg) ([]MsgEvent, error)
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

func (db *dbImpl) GetChainEvents(ctx context.Context, chainId string) ([]MsgEvent, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgEvents(ctx, chain.Num)
}

func (db *dbImpl) GetChainEventsByType(ctx context.Context, chainId string, typeUrl string) ([]MsgEvent, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgEventsByType(ctx, GetChainMsgEventsByTypeParams{
		ChainNum: chain.Num,
		Type:     typeUrl,
	})
}

func (db *dbImpl) GetChainEventAttrs(ctx context.Context, event MsgEvent) ([]MsgEventAttr, error) {
	return db.queries.GetChainMsgEventAttrs(ctx, GetChainMsgEventAttrsParams{
		ChainNum:    event.ChainNum,
		BlockHeight: event.BlockHeight,
		TxIdx:       event.TxIdx,
		MsgIdx:      event.MsgIdx,
	})
}

func (db *dbImpl) GetChainMsgSubmitProposalByPolicy(ctx context.Context, chainId string, policy string) ([]Msg, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgSubmitProposalByPolicy(ctx, GetChainMsgSubmitProposalByPolicyParams{
		ChainNum: chain.Num,
		Data:     json.RawMessage(policy),
	})
}

func (db *dbImpl) GetChainMsgEventSubmitProposalByMsg(ctx context.Context, msg Msg) ([]MsgEvent, error) {
	return db.queries.GetChainMsgEventSubmitProposalByMsg(ctx, GetChainMsgEventSubmitProposalByMsgParams{
		ChainNum:    msg.ChainNum,
		BlockHeight: msg.BlockHeight,
		TxIdx:       msg.TxIdx,
		MsgIdx:      msg.MsgIdx,
	})
}

func (db *dbImpl) GetChainMsgExecByProposal(ctx context.Context, chainId string, proposal string) ([]Msg, error) {
	chain, err := db.queries.GetChain(ctx, chainId)
	if err != nil {
		return nil, err
	}
	return db.queries.GetChainMsgExecByProposal(ctx, GetChainMsgExecByProposalParams{
		ChainNum: chain.Num,
		Data:     json.RawMessage(proposal),
	})
}

func (db *dbImpl) GetChainMsgEventExecByMsg(ctx context.Context, msg Msg) ([]MsgEvent, error) {
	return db.queries.GetChainMsgEventExecByMsg(ctx, GetChainMsgEventExecByMsgParams{
		ChainNum:    msg.ChainNum,
		BlockHeight: msg.BlockHeight,
		TxIdx:       msg.TxIdx,
		MsgIdx:      msg.MsgIdx,
	})
}
