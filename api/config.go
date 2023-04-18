package api

import (
	"github.com/spf13/viper"
)

type Config struct {
	// Port is the port the API service should run on.
	Port uint64 `mapstructure:"PORT"`

	// AllowedOrigins are the allowed origins for cross-origin requests.
	AllowedOrigins string `mapstructure:"ALLOWED_ORIGINS"`

	// DatabaseURL is the url of the postgres database.
	DatabaseURL string `mapstructure:"DATABASE_URL"`
}

func LoadConfig() Config {
	cfg := Config{}
	v := viper.New()
	v.SetDefault("PORT", 3000)
	v.SetDefault("ALLOWED_ORIGINS", "*")
	v.SetDefault("DATABASE_URL", "postgres://postgres:password@localhost/postgres?sslmode=disable")
	v.AutomaticEnv()
	if err := v.Unmarshal(&cfg); err != nil {
		panic(err)
	}
	return cfg
}
