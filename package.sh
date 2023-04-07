#!/bin/sh

fetch() {
    git clone \
        -b pldi23 --recursive --depth 1 --shallow-submodules \
        git@github.com:ccyip/$1.git
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

packages=(taype taype-driver-plaintext taype-driver-emp taype-vscode taype-theories)

# Clean up
for p in ${packages[@]}; do
    rm -rf $p
    rm -f $p.tar.xz
done

# Download the latest source code
for p in ${packages[@]}; do
    if [ "$p" == "taype-theories" ]; then
        fetch oadt
        mv oadt taype-theories
    else
        fetch $p
    fi
done

# Packaging
for p in ${packages[@]}; do
    rm -rf $p/.git
done
rm -f taype/{TODO,CHANGELOG}.md

# Create tar balls
for p in ${packages[@]}; do
    tar_ $p
done
