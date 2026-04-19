#!/bin/bash

set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: ./Scripts/Build.sh [CONFIG] [--build-dir <path>] [--projucer] [--help]

Build configuration:
  Debug | Release | RelWithDebInfo | MinSizeRel   (default: Debug)

Options:
  --build-dir <path>   CMake build directory (default: ./Builds/CMake)
  --projucer           Use legacy Projucer/Xcode/Visual Studio build script
  --help               Show this help text

Examples:
  ./Scripts/Build.sh
  ./Scripts/Build.sh Release
  ./Scripts/Build.sh --build-dir ./build
  ./Scripts/Build.sh Debug --projucer
EOF
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_CONF="Debug"
BUILD_DIR=""
USE_PROJUCER=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        Debug|Release|RelWithDebInfo|MinSizeRel)
            BUILD_CONF="$1"
            ;;
        --build-dir)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Error: --build-dir requires a value"
                exit 1
            fi
            BUILD_DIR="$1"
            ;;
        --projucer)
            USE_PROJUCER=1
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo
            show_help
            exit 1
            ;;
    esac
    shift
done

if [[ "$USE_PROJUCER" -eq 1 ]]; then
    bash "$ROOT_DIR/Scripts/Projucer/Build.sh" "$BUILD_CONF"
    exit $?
fi

if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="$ROOT_DIR/Builds/CMake"
fi

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_CONF"
cmake --build "$BUILD_DIR" --config "$BUILD_CONF"
