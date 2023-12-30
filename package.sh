#!/bin/sh

fetch() {
    REPO="$1"
    shift
    git clone \
        "$@" --recursive --depth 1 --shallow-submodules \
        https://github.com/ccyip/"$REPO".git
}

sed_() {
    if [[ $(uname) = "Darwin" ]]; then
        sed -i '' -E "$@"
    else
        sed -i'' -E "$@"
    fi
}

tar_ () {
    tar caf $1.tar.xz $1
}

set -euxo pipefail

packages=(taypsi taype-drivers taype-vscode taypsi-theories taype-pldi taype-sa taype-drivers-legacy)

# Clean up
for p in ${packages[@]}; do
    rm -rf "$p"
    rm -f "$p".tar.xz
done

# Download the latest source code
fetch taype -b oopsla24
mv taype taypsi

fetch taype-drivers -b oopsla24

fetch taype-vscode -b oopsla24

fetch oadt -b oopsla24
mv oadt taypsi-theories

fetch taype -b tape
mv taype taype-pldi

fetch taype -b tape-sa
mv taype taype-sa

mkdir -p taype-drivers-legacy
cd taype-drivers-legacy
fetch taype-driver-plaintext
fetch taype-driver-emp
cd ..

# Packaging
for p in ${packages[@]}; do
    find "$p" -name .git -exec rm -rf {} +
done
rm -rf taype-drivers-legacy/taype-driver-emp/extern

# Create tar balls
for p in ${packages[@]}; do
    tar_ "$p"
done
