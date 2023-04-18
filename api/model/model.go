package model

import (
	"encoding/json"

	"github.com/regen-network/analytics/db"
)

type ChainResponse struct {
	Num     int16  `json:"num"`
	ChainId string `json:"chain_id"`
}

type MsgResponse struct {
	ChainNum    int16           `json:"chain_num"`
	BlockHeight int64           `json:"block_height"`
	TxIdx       int16           `json:"tx_idx"`
	MsgIdx      int16           `json:"msg_idx"`
	Data        json.RawMessage `json:"data"`
}

type MsgsResponse struct {
	Msgs []MsgResponse `json:"msgs"`
}

func NewChainResponse(chain db.Chain) ChainResponse {
	return ChainResponse{
		Num:     chain.Num,
		ChainId: chain.ChainID,
	}
}

func NewMsgResponse(msg db.Msg) MsgResponse {
	return MsgResponse{
		ChainNum:    msg.ChainNum,
		BlockHeight: msg.BlockHeight,
		TxIdx:       msg.TxIdx,
		MsgIdx:      msg.MsgIdx,
		Data:        msg.Data,
	}
}

func NewMsgsResponse(msgs []db.Msg) MsgsResponse {
	ms := make([]MsgResponse, 0)
	for _, msg := range msgs {
		ms = append(ms, NewMsgResponse(msg))
	}
	return MsgsResponse{Msgs: ms}
}
