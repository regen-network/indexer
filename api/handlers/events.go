package handlers

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"

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

func GetChainEvents(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]

	events := make([]model.Event, 0)

	es, err := reader.GetChainEvents(r.Context(), chainId)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(
				w,
				http.StatusNotFound,
				fmt.Sprintf("events with chain number %s not found", chainId),
			)
			return
		}
	}

	for _, e := range es {
		eas, err := reader.GetChainEventAttrs(r.Context(), e)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				respondError(
					w,
					http.StatusNotFound,
					fmt.Sprintf("event attributes with event %s not found", e.Type),
				)
				return
			}
		}
		events = append(events, model.Event{
			Event:      e,
			EventAttrs: eas,
		})
	}

	respondJSON(w, http.StatusOK, model.NewEventsResponse(events))
}

func GetChainEventsByType(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]
	typeUrl := vars["type_url"]

	events := make([]model.Event, 0)

	es, err := reader.GetChainEventsByType(r.Context(), chainId, typeUrl)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(
				w,
				http.StatusNotFound,
				fmt.Sprintf("events with chain number %s and type %s not found", chainId, typeUrl),
			)
			return
		}
	}

	for _, e := range es {
		eas, err := reader.GetChainEventAttrs(r.Context(), e)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				respondError(
					w,
					http.StatusNotFound,
					fmt.Sprintf("event attributes with event %s not found", e.Type),
				)
				return
			}
		}
		events = append(events, model.Event{
			Event:      e,
			EventAttrs: eas,
		})
	}

	respondJSON(w, http.StatusOK, model.NewEventsResponse(events))
}

// NOTE: The following endpoint is for demonstration purposes
func GetProposalsByGroupPolicy(reader db.Reader, w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chainId := vars["chain_id"]
	address := vars["address"]

	proposals := make([]model.Proposal, 0)

	submitMsgs, err := reader.GetChainMsgSubmitProposalByPolicy(r.Context(), chainId, address)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			respondError(
				w,
				http.StatusNotFound,
				fmt.Sprintf("messages with chain id %s not found", chainId),
			)
			return
		}
	}

	for _, submitMsg := range submitMsgs {
		submitEvents, err := reader.GetChainMsgEventSubmitProposalByMsg(r.Context(), submitMsg)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				respondError(
					w,
					http.StatusNotFound,
					fmt.Sprintf("submit proposal events with chain id %s not found", chainId),
				)
				return
			}
		}

		// TODO: remove
		fmt.Println("length of submit events", len(submitEvents))

		// TODO: multiple?
		submitEvent := submitEvents[0]

		submitEventAttrs, err := reader.GetChainEventAttrs(r.Context(), submitEvent)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				respondError(
					w,
					http.StatusNotFound,
					fmt.Sprintf("event attributes with event %s not found", submitEvent.Type),
				)
				return
			}
		}

		var proposalId string

		for _, submitEventAttr := range submitEventAttrs {
			if submitEventAttr.Key == "proposal_id" {
				proposalId = strings.Trim(submitEventAttr.Value, "\"")
			}
		}

		// TODO: remove
		fmt.Println("proposal id", proposalId)

		execMsgs, err := reader.GetChainMsgExecByProposal(r.Context(), chainId, proposalId)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				respondError(
					w,
					http.StatusNotFound,
					fmt.Sprintf("messages with chain id %s not found", chainId),
				)
				return
			}
		}

		// TODO: remove
		fmt.Println("length of exec messages", len(execMsgs))

		var execEventResult string

		if len(execMsgs) > 0 {

			// TODO: multiple?
			execMsg := execMsgs[0]

			execEvents, err := reader.GetChainMsgEventExecByMsg(r.Context(), execMsg)
			if err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					respondError(
						w,
						http.StatusNotFound,
						fmt.Sprintf("exec events with chain id %s not found", chainId),
					)
					return
				}
			}

			for _, execEvent := range execEvents {
				execEventAttrs, err := reader.GetChainEventAttrs(r.Context(), execEvent)
				if err != nil {
					if errors.Is(err, sql.ErrNoRows) {
						respondError(
							w,
							http.StatusNotFound,
							fmt.Sprintf("event attributes with event %s not found", execEvent.Type),
						)
						return
					}
				}
				for _, execEventAttr := range execEventAttrs {
					if execEventAttr.Key == "result" {
						execEventResult = strings.Trim(execEventAttr.Value, "\"")
					}
				}
			}
		}

		type SubmitMsgData struct {
			Messages  []any    `json:"messages"`
			Metadata  string   `json:"metadata"`
			Proposers []string `json:"proposers"`
		}

		var submitMsgData SubmitMsgData
		err = json.Unmarshal(submitMsg.Data, &submitMsgData)
		if err != nil {
			respondError(w, http.StatusInternalServerError, err.Error())
		}

		// TODO: other results?
		if len(execEventResult) == 0 {
			execEventResult = "TODO"
		}

		proposals = append(proposals, model.Proposal{
			ExecutorResult: execEventResult,
			FinalTallyResult: model.FinalTallyResult{
				AbstainCount:    "TODO",
				NoCount:         "TODO",
				NoWithVetoCount: "TODO",
				YesCount:        "TODO",
			},
			GroupPolicyAddress: address,
			GroupPolicyVersion: "TODO",
			GroupVersion:       "TODO",
			Id:                 "TODO",
			Messages:           submitMsgData.Messages,
			Metadata:           submitMsgData.Metadata,
			Proposers:          submitMsgData.Proposers,
			Status:             "TODO",
			SubmitTime:         "TODO",
			VotingPeriodEnd:    "TODO",
		})
	}

	respondJSON(w, http.StatusOK, model.NewProposalsResponse(proposals))
}
