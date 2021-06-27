module analytics

go 1.16

replace google.golang.org/grpc => google.golang.org/grpc v1.33.2

replace github.com/gogo/protobuf => github.com/regen-network/protobuf v1.3.2-alpha.regen.4

require (
	github.com/cosmos/cosmos-sdk v0.42.6 // indirect
	github.com/jackc/pgx/v4 v4.11.0 // indirect
)
