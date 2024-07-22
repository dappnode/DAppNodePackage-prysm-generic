ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

# Use ldd to copy dependencies of grep
RUN mkdir /deps
RUN ldd /bin/grep | tr -s '[:space:]' '\n' | grep '^/' | xargs -I {} cp -v {} /deps || true

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/validator:${UPSTREAM_VERSION}

ARG NETWORK
ARG STAKER_SCRIPTS_VERSION
ARG DATA_DIR

ENV VALIDATOR_API_PORT=3500 \
  DATA_DIR=${DATA_DIR} \
  WALLET_DIR=${DATA_DIR}/prysm-wallet-v2 \
  LUKSO_CONFIG_PATH=/configs/lukso/shared/config.yaml \
  STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION} \
  LUKSO_CONFIG_URL=https://raw.githubusercontent.com/lukso-network/network-configs/main/mainnet/shared/config.yaml

COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/grep /bin/grep
COPY --from=builder /deps/* /lib/

RUN mkdir -p ${WALLET_DIR}

COPY auth-token ${WALLET_DIR}/auth-token
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ADD ${STAKER_SCRIPTS_URL}/consensus_tools.sh /etc/profile.d/

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/consensus_tools.sh

RUN if [ "${NETWORK}" = "lukso" ]; then \
  mkdir -p $(dirname ${LUKSO_CONFIG_PATH}) && \
  wget ${LUKSO_CONFIG_URL} -O ${LUKSO_CONFIG_PATH}; \
  fi

# This env changes the variant
# Placed at the end to regenerate the least amount of layers
ENV NETWORK=${NETWORK}

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]