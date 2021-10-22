FROM ubuntu:focal

######
#
# BASE
#
######

# TODO: Ubuntu focal (20.04) has git v2.25, but the minimum needed for GitHub
# Actions runners is v2.29.  For now, we build git from source.  When updating
# to hirsute (21.04) or later, we can remove the instructions to build from
# source in favor of the regular Ubuntu git package.
ARG GIT_VERSION="2.29.0"

ARG DUMB_INIT_VERSION="1.2.2"
ARG DOCKER_KEY="7EA0A9C3F273FCD8"

ENV DOCKER_COMPOSE_VERSION="1.27.4"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN echo en_US.UTF-8 UTF-8 >> /etc/locale.gen \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    awscli \
    curl \
    tar \
    unzip \
    apt-transport-https \
    ca-certificates \
    sudo \
    gpg-agent \
    gnupg \
    software-properties-common \
    build-essential \
    zlib1g-dev \
    zstd \
    gettext \
    liblttng-ust0 \
    libcurl4-openssl-dev \
    inetutils-ping \
    jq \
    wget \
    dirmngr \
    openssh-client \
    locales \
    python3-pip \
    python \
    dumb-init \
  && pip3 install --no-cache-dir awscliv2 \
  && c_rehash \
  && cd /tmp \
  && curl -sL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz -o git.tgz \
  && tar zxf git.tgz \
  && cd git-${GIT_VERSION} \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && cd / \
  # Determine the Distro name (Debian, Ubuntu, etc)
  && distro=$(lsb_release -is | awk '{print tolower($0)}') \
  # Determine the Distro version (bullseye, xenial, etc)
  # Note: sid is aliased to bullseye, because Docker doesn't have a matching apt repo
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${DOCKER_KEY} \
  && curl -fsSL https://download.docker.com/linux/${distro}/gpg | apt-key add - \
  && version=$(lsb_release -cs | awk '{gsub("sid", "bullseye"); print $0}') \
  && ( add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${distro} ${version} stable" ) \
  && apt-get update \
  && apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends --allow-unauthenticated \
  && [[ $(lscpu -J | jq -r '.lscpu[] | select(.field == "Vendor ID:") | .data') == "ARM" ]] && echo "Not installing docker-compose. See https://github.com/docker/compose/issues/6831" || ( curl -sL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose ) \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

######
#
# GHAR specifics
#
######

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.283.3"
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

RUN PREFIX=/root /root/n/bin/n 16.12.0

RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s --

ENV PATH="/root/n/bin:$PATH"
ENV PATH="/root/.yarn/bin:$PATH"
