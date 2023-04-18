package main

import (
	"fmt"
	"os"

	"github.com/rs/zerolog"

	"github.com/regen-network/analytics/api"
	"github.com/regen-network/analytics/db"
)

func main() {
	cfg := api.LoadConfig()
	log := zerolog.New(os.Stdout)
	dbs, err := db.Open(cfg.DatabaseURL, log)
	if err != nil {
		panic(err)
	}
	app := api.Initialize(cfg, db.NewDatabase(dbs), log)
	app.Run(fmt.Sprintf(":%d", cfg.Port))
}
