package model

import "github.com/regen-network/analytics/db"

type ChainResponse struct {
	Num     int16  `json:"num"`
	ChainId string `json:"chain_id"`
}

func NewChainResponse(chain db.Chain) ChainResponse {
	return ChainResponse{
		Num:     chain.Num,
		ChainId: chain.ChainID,
	}
}
