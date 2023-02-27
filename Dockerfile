FROM debian:stable

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
    rsync \
    git \
    sudo \
    unzip \
    cmake \
    libssl-dev

# Install opam
RUN echo /usr/local/bin | \
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"

# Create user
ARG guest=reviewer
RUN useradd --no-log-init -ms /bin/bash -G sudo -p '' ${guest}

USER ${guest}
WORKDIR /home/${guest}

# Install the Haskell toolchain
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.2.5
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.8.1.0
ENV BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1
ENV BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
RUN source $HOME/.ghcup/env

# Install the OCaml toolchain
RUN opam init -a -y --bare --disable-sandboxing --dot-profile="~/.bashrc" \
  && opam switch create default --package="ocaml-variants.4.14.1+options,ocaml-option-flambda" \
  && eval $(opam env) \
  && opam update -y \
  && opam install -y dune ctypes sexplib

# Copy the Taype repositories (taype, taype-driver-plaintext and taype-driver-emp)
COPY --chown=${guest}:${guest} . .

# Anonymize
RUN rm -rf {taype,taype-driver-plaintext,taype-driver-emp}/{.git,.github} \
  && rm -f taype/{TODO.md,CHANGELOG.md} \
  && shopt -s globstar \
  && sed -i "/Copyright/d" **/LICENSE \
  && sed -i "/^-- \(Copyright\|Maintainer\)/d" **/*.hs \
  && sed -i "/^\(author\|maintainer\|copyright\)/d" **/*.cabal \
  && sed -i "/\(github\|hackage\)/d" **/*.cabal **/*.md \
  && sed -i "/\(maintainers\|authors\|source\)/d" **/dune-project

# Build taype-driver-plaintext
RUN cd taype-driver-plaintext \
  && dune build \
  && dune install

# Build taype-driver-emp
RUN cd taype-driver-emp \
  && mkdir extern/{emp-tool,emp-ot,emp-sh2pc}/build \
  && mkdir src/build \
  && (cd extern/emp-tool/build && cmake .. && make && sudo make install) \
  && (cd extern/emp-ot/build && cmake .. && make && sudo make install) \
  && (cd extern/emp-sh2pc/build && cmake .. && make && sudo make install) \
  && (cd src/build && cmake .. && make && sudo make install) \
  && dune build \
  && dune install

# Build taype
RUN cd taype \
  && cabal update \
  && cabal build \
  && cabal run shake
