ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/validator:${UPSTREAM_VERSION}

ARG NETWORK
ARG STAKER_SCRIPTS_VERSION
ARG DATA_DIR=/root/.eth2validators
ARG WALLET_DIR=/root/.eth2validators/prysm-wallet-v2

COPY --from=builder /bin/sh /bin/sh

RUN mkdir -p ${WALLET_DIR}

COPY auth-token ${WALLET_DIR}/auth-token
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV VALIDATOR_API_PORT=3500 \
  DATA_DIR=${DATA_DIR} \
  WALLET_DIR=${WALLET_DIR} \
  NETWORK=${NETWORK} \
  LUKSO_CONFIG_PATH=/configs/lukso/shared/config.yaml \
  STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION} \
  LUKSO_CONFIG_URL=https://raw.githubusercontent.com/lukso-network/network-configs/main/mainnet/shared/config.yaml

ADD ${STAKER_SCRIPTS_URL}/consensus_tools.sh /etc/profile.d/

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/consensus_tools.sh

RUN if [ "${NETWORK}" = "lukso" ]; then \
  mkdir -p $(dirname ${LUKSO_CONFIG_PATH}) && \
  wget ${LUKSO_CONFIG_URL} -O ${LUKSO_CONFIG_PATH}; \
  fi

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]