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

type EventResponse struct {
	ChainNum    int16  `json:"chain_num"`
	BlockHeight int64  `json:"block_height"`
	TxIdx       int16  `json:"tx_idx"`
	MsgIdx      int16  `json:"msg_idx"`
	Type        string `json:"type"`
}

type EventsResponse struct {
	Events []EventResponse `json:"_msg_events"`
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

func NewEventResponse(event db.MsgEvent) EventResponse {
	return EventResponse{
		ChainNum:    event.ChainNum,
		BlockHeight: event.BlockHeight,
		TxIdx:       event.TxIdx,
		MsgIdx:      event.MsgIdx,
		Type:        event.Type,
	}
}

func NewEventsResponse(events []db.MsgEvent) EventsResponse {
	mes := make([]EventResponse, 0)
	for _, event := range events {
		mes = append(mes, NewEventResponse(event))
	}
	return EventsResponse{Events: mes}
}
