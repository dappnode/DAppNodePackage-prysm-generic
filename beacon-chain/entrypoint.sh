#!/bin/sh

SUPPORTED_NETWORKS="sepolia lukso holesky mainnet"
CHECKPOINT_SYNC_FLAG_1="--checkpoint-sync-url"
CHECKPOINT_SYNC_FLAG_2="--genesis-beacon-api-url"
MEVBOOST_FLAGS="--http-mev-relay"

# shellcheck disable=SC1091 # Path is relative to the Dockerfile
. /etc/profile

handle_network() {
  case "$NETWORK" in
  "holesky")
    flags_to_set="--holesky"
    ;;
  "lukso")
    flags_to_set="--chain-config-file=$LUKSO_CONFIG_PATH --contract-deployment-block=0 --bootstrap-node=enr:-MK4QJ-Bt9HATy4GQawPbDDTArtnt_phuWiVVoWKhS7-DSNjVzmGKBI9xKzpyRtpeCWd3qA9737FTdkKGDgtHfF4N-6GAYlzJCVRh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA2ulfbQgAABP__________gmlkgnY0gmlwhCKTScGJc2VjcDI1NmsxoQJNpNUERqKhA8eDDC4tovG3a59NXVOW16JDFAWXoFFTEYhzeW5jbmV0cwCDdGNwgjLIg3VkcIIu4A","enr:-MK4QDOs4pISOkkYbVHnGYHC5EhYCsVzwguun6sFZjLTqrY6Kx_AoE-YyHvqBIHDUwyQqESC4-B3o6DigPQNfKpdhXiGAYgmPWCdh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA2ulfbQgAABP__________gmlkgnY0gmlwhCIgwNOJc2VjcDI1NmsxoQNGVC8JPcsqsZPoohLP1ujAYpBfS0dBwiz4LeoUQ-k5OohzeW5jbmV0cwCDdGNwgjLIg3VkcIIu4A"
    ;;
  "mainnet")
    flags_to_set="--mainnet"
    ;;
  "sepolia")
    flags_to_set="--sepolia"
    ;;
  *)
    echo "[ERROR - entrypoint] Unsupported network: $NETWORK"
    exit 1
    ;;
  esac

  set_beacon_config_by_network "${NETWORK}" "${SUPPORTED_NETWORKS}" "$flags_to_set"
}

handle_checkpoint() {
  # Check if network is lukso and checkpoint sync url is empty
  if [ "${NETWORK}" = "lukso" ] && [ -z "${CHECKPOINT_SYNC_URL}" ]; then
    echo "[INFO - entrypoint] Syncing LUKSO chain from genesis"
    add_flag_to_extra_opts "--genesis-state=${LUKSO_GENESIS_FILE_PATH}"
  else
    # Prysm needs these 2 flags to be set for checkpoint sync
    set_checkpointsync_url "${CHECKPOINT_SYNC_FLAG_1}" "${CHECKPOINT_SYNC_URL}"
    set_checkpointsync_url "${CHECKPOINT_SYNC_FLAG_2}" "${CHECKPOINT_SYNC_URL}"
  fi
}

run_beacon() {
  echo "[INFO - entrypoint] Running beacon service"

  # shellcheck disable=SC2086
  exec /beacon-chain \
    --accept-terms-of-use \
    --datadir=${DATA_DIR} \
    --jwt-secret="${JWT_FILE_PATH}" \
    --execution-endpoint="${ENGINE_API_URL}" \
    --monitoring-host=0.0.0.0 \
    --grpc-gateway-host=0.0.0.0 \
    --grpc-gateway-port="${BEACON_API_PORT}" \
    --grpc-gateway-corsdomain="${CORSDOMAIN}" \
    --rpc-host=0.0.0.0 \
    --verbosity="${VERBOSITY}" \
    --p2p-tcp-port="${P2P_TCP_PORT}" \
    --p2p-udp-port="${P2P_UDP_PORT}" \
    --p2p-max-peers="${MAX_PEERS}" \
    --min-sync-peers="${MIN_SYNC_PEERS}" \
    --subscribe-all-subnets="${SUBSCRIBE_ALL_SUBNETS}" ${EXTRA_OPTS}
}

validate_fee_recipient
handle_network
handle_checkpoint
set_mevboost_flag "${MEVBOOST_FLAGS}"
add_flag_to_extra_opts "--suggested-fee-recipient=${FEE_RECIPIENT}"
run_beacon
