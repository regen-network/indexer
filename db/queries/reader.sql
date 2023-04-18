-- name: GetChain :one
SELECT * FROM chain WHERE chain_id=$1;

-- name: GetChainMsgs :many
SELECT * FROM msg WHERE chain_num=$1 ORDER BY block_height,tx_idx,msg_idx;

-- name: GetChainMsgsByType :many
SELECT * FROM msg WHERE chain_num=$1 AND data->>'@type'=$2 ORDER BY block_height,tx_idx,msg_idx;
