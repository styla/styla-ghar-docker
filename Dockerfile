FROM styla/ghar-node-base:latest

######
#
# GHAR specifics
#
######

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.287.1"
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /actions-runner

COPY install_actions.sh /actions-runner

RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh

COPY token.sh entrypoint.sh ephemeral-runner.sh /
RUN chmod +x /token.sh /entrypoint.sh /ephemeral-runner.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]

######
#
# GHAR tooling: yarn & n
#
######

RUN N_PREFIX=/root curl -L https://git.io/n-install | bash -s -- -q

RUN PREFIX=/root /root/n/bin/n 16.13.0

RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s --

ENV PATH="/root/n/bin:$PATH"
ENV PATH="/root/.yarn/bin:$PATH"
