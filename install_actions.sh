#!/bin/bash -ex
TARGETPLATFORM=$1

export GH_RUNNER_VERSION_LATEST=$(curl https://api.github.com/repos/actions/runner/tags | grep -m 1 name | sed -e 's/^.*name.*: "v//' | sed -e 's/",.*$//')

export TARGET_ARCH="x64"
if [[ $TARGETPLATFORM == "linux/arm/v7" ]]; then
    export TARGET_ARCH="arm"
elif [[ $TARGETPLATFORM == "linux/arm64" ]]; then
    export TARGET_ARCH="arm64"
fi

curl -L "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION_LATEST}/actions-runner-linux-${TARGET_ARCH}-${GH_RUNNER_VERSION_LATEST}.tar.gz" >actions.tar.gz

tar -zxf actions.tar.gz
rm -f actions.tar.gz

./bin/installdependencies.sh

mkdir /_work
