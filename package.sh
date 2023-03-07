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

# Clean up

rm -rf taype taype-driver-plaintext taype-driver-emp taype-vscode
rm -f taype.tar.xz taype-driver-plaintext.tar.xz taype-driver-emp.tar.xz taype-vscode.tar.xz

# Download the latest source code

fetch taype
fetch taype-driver-plaintext
fetch taype-driver-emp
fetch taype-vscode

# Anonymize

cd taype-vscode
rm -rf .git .github
sed_ '/Copyright/d' LICENSE
sed_ 's/"repository": ".*"/"repository": "anonymous"/' package.json
sed_ 's/"publisher": ".*"/"publisher": "anonymous"/' package.json
cd ..

cd taype-driver-plaintext
rm -rf .git .github
sed_ '/Copyright/d' LICENSE
sed_ '/(maintainers|authors|source)/d' dune-project
cd ..

cd taype-driver-emp
rm -rf .git .github
sed_ '/Copyright/d' LICENSE
sed_ '/(maintainers|authors|source)/d' dune-project
cd ..

cd taype
rm -rf .git .github
rm -f {TODO,CHANGELOG}.md
sed_ '/Copyright/d' LICENSE
sed_ '/^-- (Copyright|Maintainer)/d' $(find . -name '*.hs')
sed_ '/^(author|maintainer|copyright)/d' *.cabal
sed_ '/(github|hackage)/d' *.cabal *.md
cd ..

# Create tar balls

tar_ taype
tar_ taype-driver-plaintext
tar_ taype-driver-emp
tar_ taype-vscode
