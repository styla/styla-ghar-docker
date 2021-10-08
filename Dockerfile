FROM myoung34/github-runner

RUN N_PREFIX=$HOME curl -L https://git.io/n-install | bash -s -- -q
RUN PREFIX=$HOME $HOME/n/bin/n 16
RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s --
