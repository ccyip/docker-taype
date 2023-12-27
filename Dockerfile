FROM node:slim as vs-builder

WORKDIR /root
RUN npm install -g @vscode/vsce
COPY taype-vscode .
RUN vsce package -o taype.vsix


FROM python:3-slim as py-builder

WORKDIR /root
RUN pip install nbconvert
COPY taypsi/examples/figs.ipynb .
# Convert jupyter notebook to python script, so that we can still generate latex
# without starting a jupyter session
RUN jupyter nbconvert --to script figs.ipynb


FROM debian:stable

ENV LANG C.UTF-8

SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Install system dependencies
RUN apt-get update -y -q \
  && apt-get install -y -q --no-install-recommends \
    build-essential \
    curl \
    libffi-dev \
    libffi8 \
    libgmp-dev \
    libgmp10 \
    libncurses-dev \
    libncurses5 \
    libtinfo5 \
    bubblewrap \
    ca-certificates \
    pkg-config \
    sudo \
    unzip \
    cmake \
    libssl-dev \
    vim \
    python3-dev \
    python3-pip

# Install opam
RUN echo /usr/local/bin | \
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install python packages for generating figures used in the paper
RUN pip install --break-system-packages pandas numpy jinja2 ipykernel

RUN rm -rf ~/.cache

# Create user
ARG guest=reviewer
RUN useradd --no-log-init -ms /bin/bash -G sudo -p '' ${guest}

USER ${guest}
WORKDIR /home/${guest}

# Install code-server extensions and configuration
RUN mkdir -p .config/code-server
COPY --chown=${guest}:${guest} <<EOT .config/code-server/config.yaml
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOT
RUN mkdir .local
COPY --from=vs-builder --chown=${guest}:${guest} /root/taype.vsix .local
RUN code-server --install-extension haskell.haskell | grep 'was successfully installed'
RUN code-server --install-extension ocamllabs.ocaml-platform | grep 'was successfully installed'
RUN code-server --install-extension coq-community.vscoq1 | grep 'was successfully installed'
RUN code-server --install-extension ms-python.python | grep 'was successfully installed'
RUN code-server --install-extension .local/taype.vsix | grep 'was successfully installed'

# Setup shell environment
COPY --chown=${guest}:${guest} <<EOT .setup
if [ -z "\$SETUP_TAYPSI_DONE" ]; then
  export SETUP_TAYPSI_DONE=1
else
  return
fi

EOT
RUN echo 'source "$HOME/.setup"' >> ~/.profile
RUN echo 'source "$HOME/.setup"' >> ~/.bashrc

# Install the Haskell toolchain
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.4.7
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.2.0
ENV BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
RUN echo '[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"' >> ~/.setup

# Install the OCaml toolchain
RUN opam init -a -y --bare --disable-sandboxing --dot-profile="~/.setup" \
  && opam switch create default --package="ocaml-variants.4.14.1+options,ocaml-option-flambda" \
  && eval $(opam env) \
  && opam repo add coq-released https://coq.inria.fr/opam/released \
  && opam update -y \
  && opam install -y dune ctypes containers containers-data \
    sexplib yojson ppx_deriving z3

# Copy and build taype-drivers
COPY --chown=${guest}:${guest} taype-drivers taype-drivers
RUN cd taype-drivers/emp/ffi \
  && sudo make install
# Fix linker
RUN sudo /sbin/ldconfig
RUN cd taype-drivers \
  && dune build \
  && dune install

# Copy and build taype-drivers-legacy
COPY --chown=${guest}:${guest} taype-drivers-legacy taype-drivers-legacy
RUN cd taype-drivers-legacy/taype-driver-plaintext \
  && dune build \
  && dune install
RUN cd taype-drivers-legacy/taype-driver-emp \
  && dune build \
  && dune install

# Copy and build taypsi-theories (Coq formalization)
COPY --chown=${guest}:${guest} taypsi-theories taypsi-theories
RUN cd taypsi-theories && opam install -y --deps-only .
RUN cd taypsi-theories && make -j$(nproc)

# Copy and build taype-pldi
COPY --chown=${guest}:${guest} taype-pldi taype-pldi
RUN cd taype-pldi \
  && cabal update \
  && cabal build \
  && cabal run shake

# Copy and build taype-sa
COPY --chown=${guest}:${guest} taype-sa taype-sa
RUN cd taype-sa \
  && cabal update \
  && cabal build \
  && cabal run shake

# Copy and build taypsi
COPY --chown=${guest}:${guest} taypsi taypsi
RUN cd taypsi \
  && (cd solver && dune build) \
  && cabal update \
  && cabal build \
  && cabal run shake
COPY --from=py-builder --chown=${guest}:${guest} /root/figs.py taypsi/examples

# Copy other files
COPY --chown=${guest}:${guest} Dockerfile README.md bench.sh ./

# Remove some cache to save space
RUN rm -rf ~/.ghcup/cache

# Port for code-server
EXPOSE 8080

CMD ["/bin/bash", "--login"]
