FROM node:slim as vs-builder

WORKDIR /root
RUN npm install -g @vscode/vsce
COPY taype-vscode .
RUN vsce package -o taype.vsix


FROM python:3-slim as py-builder

WORKDIR /root
RUN pip install nbconvert
COPY taype/examples/figs.ipynb .
# Convert jupyter notebook to python script, so that we can still generate pdfs
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
    python3-dev \
    python3-pip

# Install opam
RUN echo /usr/local/bin | \
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install python packages for ploting
RUN pip install panda numpy seaborn ipykernel jinja2

RUN rm -rf ~/.cache

# Create user
ARG guest=reviewer
RUN useradd --no-log-init -ms /bin/bash -G sudo -p '' ${guest}

USER ${guest}
WORKDIR /home/${guest}

# Install code-server extensions and configuration
#
# These commands are not very robust, because code-server returns 0 even if it
# fails, and open-vsx.org (which is used by code-server) sometimes goes down.
RUN mkdir -p .config/code-server \
  && cd .config/code-server \
  && echo 'bind-addr: 0.0.0.0:8080' >> config.yaml \
  && echo 'auth: none' >> config.yaml \
  && echo 'cert: false' >> config.yaml
RUN mkdir .local
COPY --from=vs-builder --chown=${guest}:${guest} /root/taype.vsix .local
RUN code-server --install-extension haskell.haskell
RUN code-server --install-extension ocamllabs.ocaml-platform
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension .local/taype.vsix

# Install the Haskell toolchain
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.2.5
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.8.1.0
ENV BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
RUN echo '[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"' >> ~/.profile

# Install the OCaml toolchain
RUN opam init -a -y --bare --disable-sandboxing --dot-profile="~/.profile" \
  && opam switch create default --package="ocaml-variants.4.14.1+options,ocaml-option-flambda" \
  && eval $(opam env) \
  && opam update -y \
  && opam install -y dune ctypes sexplib

# Copy and build taype-driver-plaintext
COPY --chown=${guest}:${guest} taype-driver-plaintext taype-driver-plaintext
RUN cd taype-driver-plaintext \
  && dune build \
  && dune install

# Copy and build taype-driver-emp
COPY --chown=${guest}:${guest} taype-driver-emp taype-driver-emp
RUN cd taype-driver-emp \
  && mkdir extern/{emp-tool,emp-ot,emp-sh2pc}/build \
  && mkdir src/build \
  && (cd extern/emp-tool/build && cmake .. && make && sudo make install) \
  && (cd extern/emp-ot/build && cmake .. && make && sudo make install) \
  && (cd extern/emp-sh2pc/build && cmake .. && make && sudo make install) \
  && (cd src/build && cmake .. && make && sudo make install) \
  && dune build \
  && dune install
# Fix linker
RUN sudo /sbin/ldconfig

# Copy and build taype (compiler and examples)
COPY --chown=${guest}:${guest} taype taype
RUN cd taype \
  && cabal update \
  && cabal build \
  && cabal run shake
COPY --from=py-builder --chown=${guest}:${guest} /root/figs.py taype/examples

# Copy other files
COPY --chown=${guest}:${guest} Dockerfile README.md ./

# Port for code-server
EXPOSE 8080

CMD ["/bin/bash", "--login"]
