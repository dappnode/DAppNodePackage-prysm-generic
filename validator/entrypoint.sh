#!/bin/sh

SUPPORTED_NETWORKS="sepolia lukso holesky mainnet"
MEVBOOST_FLAG="--enable-builder"
SKIP_MEVBOOST_URL="true"
CLIENT="prysm"

handle_network() {
    case "$NETWORK" in
    "holesky")
        flags_to_set="--holesky"
        ;;
    "lukso")
        flags_to_set="--chain-config-file=${LUKSO_CONFIG_PATH}"
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

    set_validator_config_by_network "${NETWORK}" "${SUPPORTED_NETWORKS}" "${CLIENT}" "$flags_to_set"

}

get_beacon_rpc_url() {

    beacon_domain_and_protocol=$(echo "$BEACON_API_URL" | cut -d':' -f1,2)

    BEACON_RPC_4000="${beacon_domain_and_protocol}:4000"
}

run_validator() {
    echo "[INFO - entrypoint] Running validator service"

    # shellcheck disable=SC2086
    exec /validator \
        --datadir="${DATA_DIR}" \
        --wallet-dir="${WALLET_DIR}" \
        --monitoring-host 0.0.0.0 \
        --beacon-rpc-provider="${BEACON_API_URL}" \
        --beacon-rpc-gateway-provider="${BEACON_RPC_4000}" \
        --validators-external-signer-url="${WEB3SIGNER_API_URL}" \
        --grpc-gateway-host=0.0.0.0 \
        --grpc-gateway-port="${VALIDATOR_API_PORT}" \
        --grpc-gateway-corsdomain=http://0.0.0.0:"${VALIDATOR_API_PORT}" \
        --graffiti="${GRAFFITI}" \
        --suggested-fee-recipient="${FEE_RECIPIENT}" \
        --verbosity="${VERBOSITY}" \
        --web \
        --accept-terms-of-use \
        --enable-doppelganger ${EXTRA_OPTS}
}

format_graffiti
handle_network
get_beacon_rpc_url
set_mevboost_flag "${MEVBOOST_FLAG}" "${SKIP_MEVBOOST_URL}"
run_validator
