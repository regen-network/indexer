package api

import (
	"log"
	"net/http"
	"strings"

	gHandlers "github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/rs/zerolog"

	"github.com/regen-network/analytics/api/handlers"
	"github.com/regen-network/analytics/db"
)

type App struct {
	db             db.Reader
	logger         zerolog.Logger
	router         *mux.Router
	allowedOrigins string
}

// Initialize initializes the app with a router, database and logger, and inits the routes for the REST API.
func Initialize(cfg Config, reader db.Reader, logger zerolog.Logger) *App {
	app := &App{
		db:             reader,
		logger:         logger,
		router:         mux.NewRouter(),
		allowedOrigins: cfg.AllowedOrigins,
	}
	app.initRouters()
	return app
}

// Run blocks the current thread of execution and serves the API.
func (a *App) Run(host string) {
	allowedOrigins := gHandlers.AllowedOrigins(strings.Split(a.allowedOrigins, ","))
	log.Fatal(http.ListenAndServe(host, gHandlers.CORS(allowedOrigins)(a.router)))
}

// Get wraps the router for GET method
func (a *App) Get(path string, f func(w http.ResponseWriter, r *http.Request)) {
	a.router.HandleFunc(path, f).Methods("GET")
}

func (a *App) initRouters() {
	a.Get("/chain/{chain_id}", a.handleRequest(handlers.GetChain))
	a.Get("/chain/{chain_id}/msgs", a.handleRequest(handlers.GetChainMsgs))
	a.Get("/chain/{chain_id}/msgs/{type_url}", a.handleRequest(handlers.GetChainMsgsByType))
	a.Get("/chain/{chain_id}/events", a.handleRequest(handlers.GetChainEvents))
	a.Get("/chain/{chain_id}/events/{type_url}", a.handleRequest(handlers.GetChainEventsByType))
}

type RequestHandlerFunction func(db db.Reader, w http.ResponseWriter, r *http.Request)

func (a *App) handleRequest(handler RequestHandlerFunction) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(a.db, w, r)
	}
}
