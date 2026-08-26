#!/bin/sh

CHECKPOINT_SYNC_FLAG_KEY_1="--checkpoint-sync-url"
CHECKPOINT_SYNC_FLAG_KEY_2="--genesis-beacon-api-url"
MEVBOOST_FLAG_KEY="--http-mev-relay"

# shellcheck disable=SC1091 # Path is relative to the Dockerfile
. /etc/profile.d/consensus_tools.sh

ENGINE_URL="http://execution.${NETWORK}.staker.dappnode:8551"

if [ "$NETWORK" = "sepolia" ]; then
  ENGINE_URL="http://sepolia-geth.dappnode:8551"
fi

VALID_FEE_RECIPIENT=$(get_valid_fee_recipient "${FEE_RECIPIENT_ADDRESS}")
MEVBOOST_FLAG=$(get_mevboost_flag "${NETWORK}" "${MEVBOOST_FLAG_KEY}")

JWT_SECRET=$(get_jwt_secret_by_network "${NETWORK}")
echo "${JWT_SECRET}" >"${JWT_FILE_PATH}"

# To avoid failure for users who have added fee recipient to extra opts
EXTRA_OPTS=$(add_flag_to_extra_opts_safely "${EXTRA_OPTS}" "--suggested-fee-recipient=${VALID_FEE_RECIPIENT}")

# https://github.com/lukso-network/network-configs/blob/main/mainnet/prysm/prysm.yaml
LUKSO_BOOTSTRAP_NODES="enr:-MK4QHcS3JeTtVjOuJyVXvO1E6XJWqiwmhLfodel6vARPI8ve_2q9vVn8LpIL964qBId7zGpSVKw6oOPAaRm2H7ywYiGAYmHDeBbh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA2ulfbQgAABP__________gmlkgnY0gmlwhCIgwNOJc2VjcDI1NmsxoQNGVC8JPcsqsZPoohLP1ujAYpBfS0dBwiz4LeoUQ-k5OohzeW5jbmV0cwCDdGNwgjLIg3VkcIIu4A,enr:-Ly4QF7f-m7CiC1EwxmEa3VosxSUAeBaegcOek-J2DgqkB9EHyo5UOCZKAKuGN3pt3S28HVZy1PS6CGILRa8h25pZCsFh2F0dG5ldHOI__________-EZXRoMpCq3eQ4QgAABv__________gmlkgnY0gmlwhLJobp6Jc2VjcDI1NmsxoQJ88Tw_HsGhSdHp8AflKAJnt7VyHNDakc57AT6jdaBihIhzeW5jbmV0cw-DdGNwgiMog3VkcIIjKA,enr:-Jq4QABOsAAluqXVlLuAAWcMtYF__YTHcAWCChtvzXYa2GMuB5bEFaRnsoCuXUHTx4hxABFwwG29eQd3vH4GCZQbgdEBhGV0aDKQ3FGxEUIAAASkHwAAAAAAAIJpZIJ2NIJpcIQ5gLgeiXNlY3AyNTZrMaECWsDTDT1LTmpENdKPc6IbbViy5D1mahB4AJnPOCafYjKDdWRwgiMy"

case "$NETWORK" in
"hoodi")
  NETWORK_FLAGS="--hoodi"
  ;;
"lukso")
  NETWORK_FLAGS="--chain-config-file=$LUKSO_CHAIN_CONFIG_FILE_PATH --contract-deployment-block=0 --bootstrap-node=$LUKSO_BOOTSTRAP_NODES"
  ;;
"mainnet")
  NETWORK_FLAGS="--mainnet"
  ;;
"sepolia")
  NETWORK_FLAGS="--sepolia"
  ;;
*)
  echo "[ERROR - entrypoint] Unsupported network: $NETWORK"
  exit 1
  ;;
esac

# Check if network is lukso and checkpoint sync url is empty
if [ -z "${CHECKPOINT_SYNC_URL}" ]; then

  if [ "${NETWORK}" = "lukso" ]; then
    echo "[INFO - entrypoint] Syncing LUKSO chain from genesis"
    EXTRA_OPTS=$(add_flag_to_extra_opts_safely "${EXTRA_OPTS}" "--genesis-state=${LUKSO_GENESIS_FILE_PATH}")

  elif [ "${NETWORK}" = "sepolia" ]; then
    echo "[INFO - entrypoint] Syncing sepolia chain from genesis"
    EXTRA_OPTS=$(add_flag_to_extra_opts_safely "${EXTRA_OPTS}" "--genesis-state=${SEPOLIA_GENESIS_FILE_PATH}")
  fi

else
  # Prysm needs these 2 flags to be set for checkpoint sync
  checkpoint_flag_1=$(get_checkpoint_sync_flag "${CHECKPOINT_SYNC_FLAG_KEY_1}" "${CHECKPOINT_SYNC_URL}")
  checkpoint_flag_2=$(get_checkpoint_sync_flag "${CHECKPOINT_SYNC_FLAG_KEY_2}" "${CHECKPOINT_SYNC_URL}")

  CHECKPOINT_SYNC_FLAGS="${checkpoint_flag_1} ${checkpoint_flag_2}"
fi

FLAGS="--accept-terms-of-use \
  --blob-storage-layout=by-epoch \
  --datadir=$DATA_DIR \
  --jwt-secret=$JWT_FILE_PATH \
  --execution-endpoint=$ENGINE_URL \
  --monitoring-host=0.0.0.0 \
  --http-host=0.0.0.0 \
  --http-port=$BEACON_API_PORT \
  --http-cors-domain=$CORSDOMAIN \
  --rpc-host=0.0.0.0 \
  --verbosity=$VERBOSITY \
  --p2p-tcp-port=$P2P_TCP_PORT \
  --p2p-udp-port=$P2P_UDP_PORT \
  --p2p-max-peers=$MAX_PEERS \
  --min-sync-peers=$MIN_SYNC_PEERS \
  --subscribe-all-subnets=$SUBSCRIBE_ALL_SUBNETS $NETWORK_FLAGS $CHECKPOINT_SYNC_FLAGS $MEVBOOST_FLAG $EXTRA_OPTS"

echo "[INFO - entrypoint] Starting beacon with flags: $FLAGS"

# shellcheck disable=SC2086
exec /beacon-chain $FLAGS
