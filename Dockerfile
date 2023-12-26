FROM node:slim as vs-builder

WORKDIR /root
RUN npm install -g @vscode/vsce
ADD taype-vscode.tar.xz .
RUN cd taype-vscode && vsce package -o /root/taype.vsix


FROM python:3-slim as py-builder

WORKDIR /root
RUN pip install nbconvert
ADD taypsi.tar.xz .
RUN cp taypsi/examples/figs.ipynb .
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
    libffi7 \
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
    python3-pandas \
    python3-jinja2 \
    python3-ipykernel

# Install opam
RUN echo /usr/local/bin | \
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN rm -rf ~/.cache

# Create user
ARG guest=reviewer
RUN useradd --no-log-init -ms /bin/bash -G sudo -p '' ${guest}

USER ${guest}
WORKDIR /home/${guest}

# Install code-server extensions and configuration
RUN mkdir -p .config/code-server \
  && cd .config/code-server \
  && echo 'bind-addr: 0.0.0.0:8080' >> config.yaml \
  && echo 'auth: none' >> config.yaml \
  && echo 'cert: false' >> config.yaml
RUN mkdir .local
COPY --from=vs-builder --chown=${guest}:${guest} /root/taype.vsix .local
RUN code-server --install-extension haskell.haskell | grep 'was successfully installed'
RUN code-server --install-extension ocamllabs.ocaml-platform | grep 'was successfully installed'
RUN code-server --install-extension coq-community.vscoq1 | grep 'was successfully installed'
RUN code-server --install-extension ms-python.python | grep 'was successfully installed'
RUN code-server --install-extension .local/taype.vsix | grep 'was successfully installed'

# Setup shell environment
COPY <<EOT ~/.setup
if [ -z "$SETUP_TAYPSI_DONE" ]; then
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
ADD --chown=${guest}:${guest} taype-drivers.tar.xz .
RUN cd taype-drivers \
  && (cd emp/ffi && sudo make install) \
  && dune build \
  && dune install

# Copy and build taype-drivers-legacy
ADD --chown=${guest}:${guest} taype-drivers-legacy.tar.xz .
RUN cd taype-drivers-legacy/taype-driver-plaintext \
  && dune build \
  && dune install
RUN cd taype-drivers-legacy/taype-driver-emp \
  && dune build \
  && dune install

# Fix linker
RUN sudo /sbin/ldconfig

# Copy and build taypsi-theories (Coq formalization)
ADD --chown=${guest}:${guest} taypsi-theories.tar.xz .
RUN cd taypsi-theories && opam install -y --deps-only .
RUN cd taypsi-theories && make -j$(nproc)

# Copy and build taype-pldi
ADD --chown=${guest}:${guest} taype-pldi.tar.xz .
RUN cd taype-pldi \
  && cabal update \
  && cabal build \
  && cabal run shake

# Copy and build taype-sa
ADD --chown=${guest}:${guest} taype-sa.tar.xz .
RUN cd taype-sa \
  && cabal update \
  && cabal build \
  && cabal run shake

# Copy and build taypsi
ADD --chown=${guest}:${guest} taypsi.tar.xz .
RUN cd taypsi \
  && (cd solver && dune build) \
  && cabal update \
  && cabal build \
  && cabal run shake
COPY --from=py-builder --chown=${guest}:${guest} /root/figs.py taypsi/examples

# Copy other files
COPY --chown=${guest}:${guest} Dockerfile README.md ./

# Remove some cache to save space
RUN rm -rf ~/.ghcup/cache

# Port for code-server
EXPOSE 8080

CMD ["/bin/bash", "--login"]
