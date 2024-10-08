ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

ARG NETWORK

# Use ldd to copy dependencies of grep
RUN mkdir /deps && \
    ldd /bin/grep | tr -s '[:space:]' '\n' | grep '^/' | xargs -I {} cp -v {} /deps || true && \
    apt-get update && \
    apt-get --yes install wget

ENV LUKSO_CONFIG_PATH=/configs/lukso \
    LUKSO_SHARED_CONFIG_URL=https://raw.githubusercontent.com/lukso-network/network-configs/main/mainnet/shared/dencun \
    SEPOLIA_CONFIG_PATH=/configs/sepolia \
    SEPOLIA_GENESIS_URL=https://raw.githubusercontent.com/eth-clients/sepolia/main/metadata/genesis.ssz


RUN mkdir -p ${LUKSO_CONFIG_PATH} ${SEPOLIA_CONFIG_PATH} && \
    if [ "${NETWORK}" = "lukso" ]; then \
    wget ${LUKSO_SHARED_CONFIG_URL}/genesis.ssz -O ${LUKSO_CONFIG_PATH}/genesis.ssz && \
    wget ${LUKSO_SHARED_CONFIG_URL}/config.yaml -O ${LUKSO_CONFIG_PATH}/config.yaml; \
    elif [ "${NETWORK}" = "sepolia" ]; then \
    wget ${SEPOLIA_GENESIS_URL} -O ${SEPOLIA_CONFIG_PATH}/genesis.ssz; \
    fi

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/beacon-chain:${UPSTREAM_VERSION}

ARG NETWORK
ARG STAKER_SCRIPTS_VERSION
ARG DATA_DIR
ARG P2P_TCP_PORT
ARG P2P_UDP_PORT

ENV JWT_FILE_PATH=/jwtsecret.hex \
    BEACON_API_PORT=3500 \
    P2P_TCP_PORT=${P2P_TCP_PORT} \
    P2P_UDP_PORT=${P2P_UDP_PORT} \
    DATA_DIR=${DATA_DIR} \
    CONFIGS_PATH=/configs \
    STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ADD ${STAKER_SCRIPTS_URL}/consensus_tools.sh /etc/profile.d/

COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/grep /bin/grep
COPY --from=builder /deps/* /lib/

COPY --from=builder /configs /configs

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/consensus_tools.sh

# This env changes the variant
# Placed at the end to regenerate the least amount of layers
ENV NETWORK=${NETWORK} \
    SEPOLIA_GENESIS_FILE_PATH=${CONFIGS_PATH}/sepolia/genesis.ssz \
    LUKSO_GENESIS_FILE_PATH=${CONFIGS_PATH}/lukso/genesis.ssz \
    LUKSO_CHAIN_CONFIG_FILE_PATH=${CONFIGS_PATH}/lukso/config.yaml

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]