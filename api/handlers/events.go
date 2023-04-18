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
