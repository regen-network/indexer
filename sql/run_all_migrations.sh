#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace
psql -c "\i V1__init.sql" $DATABASE_URL
psql -c "\i V1_1__fix_msg_attr.sql" $DATABASE_URL
psql -c "\i V1_2__add_retirements_table.sql" $DATABASE_URL
psql -c "\i V1_3__add_msg_event_attr_type_idx.sql" $DATABASE_URL
psql -c "\i V1_4__retirements_owner_idx.sql" $DATABASE_URL
