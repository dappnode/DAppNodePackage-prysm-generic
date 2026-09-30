ARG UPSTREAM_VERSION

FROM debian:bookworm-slim AS builder

ARG NETWORK

RUN apt-get update && \
  apt-get --yes install --no-install-recommends ca-certificates wget && \
  rm -rf /var/lib/apt/lists/*

ENV LUKSO_CONFIG_URL=https://raw.githubusercontent.com/lukso-network/network-configs/main/mainnet/shared/pectra/config.yaml

RUN if [ "${NETWORK}" = "lukso" ]; then \
  wget ${LUKSO_CONFIG_URL} -O /lukso-config.yaml; \
  else \
  touch /lukso-config.yaml; \
  fi

# Match Prysm's Bullseye runtime; this stage does not need APT repositories.
FROM debian:bullseye-slim AS tools

RUN mkdir /deps && \
  ldd /bin/grep | tr -s '[:space:]' '\n' | grep '^/' | xargs -I {} cp -v {} /deps

FROM gcr.io/prysmaticlabs/prysm/validator:${UPSTREAM_VERSION}

ARG NETWORK
ARG STAKER_SCRIPTS_VERSION
ARG DATA_DIR

ENV VALIDATOR_API_PORT=3500 \
  DATA_DIR=${DATA_DIR} \
  WALLET_DIR=${DATA_DIR}/prysm-wallet-v2 \
  LUKSO_CONFIG_PATH=/configs/lukso/shared/config.yaml \
  STAKER_SCRIPTS_URL=https://github.com/dappnode/staker-package-scripts/releases/download/${STAKER_SCRIPTS_VERSION}

COPY --from=tools /bin/sh /bin/sh
COPY --from=tools /bin/grep /bin/grep
COPY --from=tools /deps/* /lib/
COPY --from=builder /lukso-config.yaml ${LUKSO_CONFIG_PATH}

RUN mkdir -p ${WALLET_DIR} $(dirname ${LUKSO_CONFIG_PATH})

COPY auth-token ${WALLET_DIR}/auth-token
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ADD ${STAKER_SCRIPTS_URL}/consensus_tools.sh /etc/profile.d/

RUN chmod +rx /usr/local/bin/entrypoint.sh /etc/profile.d/consensus_tools.sh

# This env changes the variant
# Placed at the end to regenerate the least amount of layers
ENV NETWORK=${NETWORK}

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
