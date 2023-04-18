-- name: GetChain :one
SELECT * FROM chain WHERE chain_id=$1;

-- name: GetChainMsgs :many
SELECT * FROM msg WHERE chain_num=$1 ORDER BY block_height,tx_idx,msg_idx;

-- name: GetChainMsgsByType :many
SELECT * FROM msg WHERE chain_num=$1 AND data->>'@type'=$2 ORDER BY block_height,tx_idx,msg_idx;

-- name: GetChainMsgEvents :many
SELECT * FROM msg_event WHERE chain_num=$1 ORDER BY block_height,tx_idx,msg_idx;

-- name: GetChainMsgEventsByType :many
SELECT * FROM msg_event WHERE chain_num=$1 AND type=$2 ORDER BY block_height,tx_idx,msg_idx;

-- name: GetChainMsgEventAttrs :many
SELECT * FROM msg_event_attr WHERE chain_num=$1 AND block_height=$2 AND tx_idx=$3 AND msg_idx=$4;
