#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./scripts/update-nwn-compiler.sh [RELEASE_TAG]

Install or update nwn_script_comp from niv/neverwinter.nim releases.
Defaults to the latest stable release; optionally specify a tag such as 2.3.1.
Export NWN_TOOLS first by explicitly loading your project .env:

    set -a
    source .env
    set +a

Requires Linux, curl, and unzip. Supports x86_64 and aarch64.
EOF
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    usage
    exit 0
fi
if (( $# > 1 )); then
    usage >&2
    exit 1
fi
if [[ -z ${NWN_TOOLS:-} ]]; then
    echo 'NWN_TOOLS is unset or empty. Export it by loading your project .env first.' >&2
    exit 1
fi
if [[ $(uname -s) != Linux ]]; then
    echo 'This updater supports Linux only.' >&2
    exit 1
fi
case $(uname -m) in
    x86_64) architecture=x86_64 ;;
    aarch64|arm64) architecture=aarch64 ;;
    *) echo 'Unsupported architecture: use an upstream source build instead.' >&2; exit 1 ;;
esac
for dependency in curl unzip; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "Missing $dependency. Install dependencies with: sudo apt install curl unzip" >&2
        exit 1
    fi
done

release=${1:-latest}
asset="neverwinter-${architecture}-linux-gnu.zip"
release_base=https://github.com/niv/neverwinter.nim/releases
if [[ $release == latest ]]; then
    release_url=$(curl --fail --location --silent --show-error --retry 2 \
        --connect-timeout 20 --max-time 60 --head --output /dev/null \
        --write-out '%{url_effective}' "$release_base/latest")
    release=${release_url##*/}
fi
if [[ ! $release =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ || $release == latest ]]; then
    echo 'Invalid release tag.' >&2
    exit 1
fi
download_url="$release_base/download/$release/$asset"

compiler_tmp=$(mktemp -d)
staged_compiler=''
cleanup() {
    rm -rf -- "$compiler_tmp"
    if [[ -n $staged_compiler ]]; then
        rm -f -- "$staged_compiler"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Downloading $release ($architecture)..."
curl --fail --location --silent --show-error --retry 2 \
    --connect-timeout 20 --max-time 300 \
    --output "$compiler_tmp/neverwinter.zip" "$download_url"
unzip -q "$compiler_tmp/neverwinter.zip" nwn_script_comp -d "$compiler_tmp"
chmod 755 "$compiler_tmp/nwn_script_comp"

# Check that the downloaded executable runs before replacing an existing compiler.
"$compiler_tmp/nwn_script_comp" --help >/dev/null
mkdir -p -- "$NWN_TOOLS"
staged_compiler=$(mktemp "$NWN_TOOLS/.nwn_script_comp.XXXXXX")
cp -- "$compiler_tmp/nwn_script_comp" "$staged_compiler"
chmod 755 "$staged_compiler"
mv -fT -- "$staged_compiler" "$NWN_TOOLS/nwn_script_comp"
staged_compiler=''

echo "Installed $release: $NWN_TOOLS/nwn_script_comp"
echo "Release asset: $download_url"
