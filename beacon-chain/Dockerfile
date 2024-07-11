ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

ARG NETWORK

# Use ldd to copy dependencies of grep
RUN mkdir /deps
RUN ldd /bin/grep | tr -s '[:space:]' '\n' | grep '^/' | xargs -I {} cp -v {} /deps || true

ENV LUKSO_CONFIG_PATH=/configs/lukso \
    LUKSO_SHARED_CONFIG_URL=https://raw.githubusercontent.com/lukso-network/network-configs/main/mainnet/shared

RUN mkdir -p ${LUKSO_CONFIG_PATH} && \
    if [ "${NETWORK}" = "lukso" ]; then \
    wget ${LUKSO_SHARED_CONFIG_URL}/genesis.ssz -O ${LUKSO_CONFIG_PATH}/genesis.ssz && \
    wget ${LUKSO_SHARED_CONFIG_URL}/config.yaml -O ${LUKSO_CONFIG_PATH}/config.yaml; \
    fi

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/beacon-chain:${UPSTREAM_VERSION}

ARG NETWORK
ARG STAKER_SCRIPTS_VERSION
ARG DATA_DIR

ENV JWT_FILE_PATH=/jwtsecret \
    BEACON_API_PORT=3500 \
    DATA_DIR=${DATA_DIR} \
    LUKSO_CONFIG_PATH=/configs/lukso \
    LUKSO_GENESIS_FILE_PATH=${LUKSO_CONFIG_PATH}/genesis.ssz \
    LUKSO_CHAIN_CONFIG_FILE_PATH=${LUKSO_CONFIG_PATH}/config.yaml \
    STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION}

COPY jwtsecret.hex ${JWT_FILE_PATH}
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ADD ${STAKER_SCRIPTS_URL}/consensus_tools.sh /etc/profile.d/

COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/grep /bin/grep
COPY --from=builder /deps/* /lib/

COPY --from=builder /configs /configs

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/consensus_tools.sh

# This env changes the variant
# Placed at the end to regenerate the least amount of layers
ENV NETWORK=${NETWORK}

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]