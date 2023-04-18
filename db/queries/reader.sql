-- name: GetChain :one
SELECT * FROM chain WHERE chain_id=$1;
