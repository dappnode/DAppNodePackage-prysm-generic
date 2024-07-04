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

COPY jwtsecret.hex /jwtsecret
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/grep /bin/grep
COPY --from=builder /deps/* /lib/

ENV JWT_PATH=/jwtsecret \
    VALIDATOR_PORT=3500 \
    DATA_DIR=/data \
    LUKSO_CONFIG_PATH=/configs/lukso \
    LUKSO_GENESIS_FILE_PATH=${LUKSO_CONFIG_PATH}/genesis.ssz \
    LUKSO_CHAIN_CONFIG_FILE_PATH=${LUKSO_CONFIG_PATH}/config.yaml

COPY --from=builder /configs /configs

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]