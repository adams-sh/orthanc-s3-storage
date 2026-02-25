#!/usr/bin/env bash
# Native macOS build script for the Orthanc S3 Storage plugin.
# Tested on macOS Sequoia (15.x).
#
# Prerequisites (install via Homebrew):
#   brew install cmake openssl curl zlib mercurial
#
# Usage:
#   scripts/build-macos.sh

set -euo pipefail

die() {
    echo "$*" >&2
    exit 1
}

ROOT_DIR=$(git rev-parse --show-toplevel) || die "This script must be run from within the git repository. Please cd to the repository root and try again."

pushd "$(pwd)" > /dev/null
cd "$ROOT_DIR"

BUILD_DIR="$ROOT_DIR/build"
INSTALL_DIR="$ROOT_DIR/install"
mkdir -p "$BUILD_DIR"

# Prefer Homebrew-installed OpenSSL when available
OPENSSL_ROOT=""
if command -v brew > /dev/null 2>&1; then
    BREW_OPENSSL="$(brew --prefix openssl 2>/dev/null || true)"
    if [ -n "$BREW_OPENSSL" ] && [ -d "$BREW_OPENSSL" ]; then
        OPENSSL_ROOT="$BREW_OPENSSL"
        export PKG_CONFIG_PATH="$BREW_OPENSSL/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
        export OPENSSL_ROOT_DIR="$BREW_OPENSSL"
    fi
fi

cd "$BUILD_DIR" || die "Cannot change to build directory."

cmake "$ROOT_DIR" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    -DALLOW_DOWNLOADS=ON \
    -DSTANDALONE_BUILD=ON \
    -DSTATIC_BUILD=OFF \
    -DUSE_SYSTEM_BOOST=OFF \
    -DUSE_SYSTEM_CURL=ON \
    -DUSE_SYSTEM_MONGOOSE=OFF \
    -DUSE_SYSTEM_PUGIXML=OFF \
    -DUSE_SYSTEM_GOOGLE_TEST=OFF \
    -DUSE_SYSTEM_UUID=OFF \
    -DUSE_SYSTEM_DCMTK=OFF \
    -DUSE_SYSTEM_JSONCPP=OFF \
    -DUSE_SYSTEM_ORTHANC_SDK=OFF \
    -DUSE_SYSTEM_AWS_SDK=OFF \
    ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR="$OPENSSL_ROOT"} \
    || die "cmake configuration failed."

cmake --build . -- -j"$(sysctl -n hw.logicalcpu)" || die "Build failed."
cmake --build . --target install

popd > /dev/null
