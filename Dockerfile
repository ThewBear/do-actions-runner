FROM ubuntu

RUN useradd -m actions
RUN apt-get -y update && apt-get install -y \
    apt-transport-https ca-certificates curl jq software-properties-common \
    && toolset="$(curl -sL https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/toolsets/toolset-2004.json)" \
    && common_packages=$(echo $toolset | jq -r ".apt.common_packages[]") && cmd_packages=$(echo $toolset | jq -r ".apt.cmd_packages[]") \
    && for package in $common_packages $cmd_packages; do apt-get install -y --no-install-recommends $package; done

RUN \
    RUNNER_VERSION="$(curl -s -X GET 'https://api.github.com/repos/actions/runner/releases/latest' | jq -r '.tag_name|ltrimstr("v")')" \
    && cd /home/actions && mkdir actions-runner && cd actions-runner \
    && wget https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R actions ~actions

RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git

# Install LTS Node.js and related build tools
RUN curl -sL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s -- -ny - \
    && ~/n/bin/n lts \
    && npm install -g grunt gulp n parcel-bundler typescript newman \
    && npm install -g --save-dev webpack webpack-cli \
    && npm install -g npm \
    && rm -rf ~/n

WORKDIR /home/actions/actions-runner

USER actions
COPY --chown=actions:actions entrypoint.sh .
RUN chmod u+x ./entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
