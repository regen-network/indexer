package handlers

import (
	"database/sql"
	"errors"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/regen-network/analytics/api/model"
	"github.com/regen-network/analytics/db"
)

func GetChain(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]

	chain, err := reader.GetChain(r.Context(), chainId)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(w, http.StatusNotFound, fmt.Sprintf("chain with id %s not found", chainId))
			return
		}
	}

	respondJSON(w, http.StatusOK, model.NewChainResponse(chain))
}

func GetChainMsgs(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]

	msgs, err := reader.GetChainMsgs(r.Context(), chainId)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(
				w,
				http.StatusNotFound,
				fmt.Sprintf("messages with chain number %s not found", chainId),
			)
			return
		}
	}

	respondJSON(w, http.StatusOK, model.NewMsgsResponse(msgs))
}

func GetChainMsgsByType(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]
	typeUrl := vars["type_url"]

	msgs, err := reader.GetChainMsgsByType(r.Context(), chainId, typeUrl)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(
				w,
				http.StatusNotFound,
				fmt.Sprintf("messages with chain number %s and type %s not found", chainId, typeUrl),
			)
			return
		}
	}

	respondJSON(w, http.StatusOK, model.NewMsgsResponse(msgs))
}
