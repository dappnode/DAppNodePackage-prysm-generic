#!/bin/sh

SUPPORTED_NETWORKS="sepolia lukso holesky mainnet"
MEVBOOST_FLAG_KEY="--enable-builder"
SKIP_MEVBOOST_URL="true"
CLIENT="prysm"

# shellcheck disable=SC1091
. /etc/profile.d/consensus_tools.sh

VALID_GRAFFITI=$(get_valid_graffiti "${GRAFFITI}")
VALID_FEE_RECIPIENT=$(get_valid_fee_recipient "${FEE_RECIPIENT}")
SIGNER_API_URL=$(get_signer_api_url "${NETWORK}" "${SUPPORTED_NETWORKS}")
BEACON_API_URL=$(get_beacon_api_url "${NETWORK}" "${SUPPORTED_NETWORKS}" "${CLIENT}")
MEVBOOST_FLAG=$(get_mevboost_flag "${MEVBOOST_FLAG_KEY}" "${SKIP_MEVBOOST_URL}")

# Extract the hostname from BEACON_API_URL and append port 4000
BEACON_API_4000="$(echo "$BEACON_API_URL" | cut -d'/' -f3 | cut -d':' -f1):4000"

case "$NETWORK" in
"holesky")
    NETWORK_FLAGS="--holesky"
    ;;
"lukso")
    NETWORK_FLAGS="--chain-config-file=${LUKSO_CONFIG_PATH}"
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

echo "[INFO - entrypoint] Running validator service"

# shellcheck disable=SC2086
exec /validator \
    --datadir="${DATA_DIR}" \
    --wallet-dir="${WALLET_DIR}" \
    --monitoring-host 0.0.0.0 \
    --beacon-rpc-provider="${BEACON_API_4000}" \
    --beacon-rpc-gateway-provider="${BEACON_API_URL}" \
    --validators-external-signer-url="${SIGNER_API_URL}" \
    --grpc-gateway-host=0.0.0.0 \
    --grpc-gateway-port="${VALIDATOR_API_PORT}" \
    --grpc-gateway-corsdomain=http://0.0.0.0:"${VALIDATOR_API_PORT}" \
    --graffiti="${VALID_GRAFFITI}" \
    --suggested-fee-recipient="${VALID_FEE_RECIPIENT}" \
    --verbosity="${VERBOSITY}" \
    --web \
    --accept-terms-of-use \
    --enable-doppelganger ${NETWORK_FLAGS} ${MEVBOOST_FLAG} ${EXTRA_OPTS}
