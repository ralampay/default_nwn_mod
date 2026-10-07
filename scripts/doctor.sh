#!/usr/bin/env bash
set -uo pipefail

usage() {
    cat <<'EOF'
Usage: ./scripts/doctor.sh

Check the exported NWN project environment without modifying any files.
Load your environment explicitly before running:

    set -a
    source .env
    set +a
    export PATH="$NWN_TOOLS:$PATH"
    ./scripts/doctor.sh

Exit status: 0 when required checks pass, 1 on setup errors, 2 on invalid usage.
Optional user-resource directories produce warnings only.
EOF
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    usage
    exit 0
fi
if (( $# != 0 )); then
    usage >&2
    exit 2
fi

errors=0
warnings=0
ok() { printf 'OK: %s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*"; errors=$((errors + 1)); }
warn() { printf 'WARNING: %s\n' "$*"; warnings=$((warnings + 1)); }

if [[ $(uname -s) == Linux ]]; then
    ok 'Running on Linux.'
else
    fail 'This template expects Ubuntu/Linux.'
fi

check_directory() {
    local name=$1 value=${!1:-}
    if [[ -z $value ]]; then
        fail "$name is unset or empty. Load .env with set -a; source .env; set +a."
        return 1
    fi
    if [[ $value == *XXXXXXXX* || $value == *'<APP_ID>'* ]]; then
        fail "$name contains an example placeholder. Edit your local .env."
        return 1
    fi
    if [[ $value != /* ]]; then
        fail "$name must be an absolute path (use \"\$HOME/...\" in .env): $value"
        return 1
    fi
    if [[ ! -d $value ]]; then
        fail "$name directory does not exist: $value"
        return 1
    fi
    if [[ ! -r $value || ! -x $value ]]; then
        fail "$name directory is not readable/searchable: $value"
        return 1
    fi
    ok "$name: $value"
}

tools_ready=0
if check_directory NWN_TOOLS; then tools_ready=1; fi
check_directory NWN_ROOT || :
if check_directory NWN_HOME; then
    if [[ ! -w $NWN_HOME ]]; then
        fail "NWN_HOME is not writable: $NWN_HOME"
    fi
    for resource in modules hak override localvault logs; do
        if [[ ! -d $NWN_HOME/$resource ]]; then
            warn "Optional directory missing: $NWN_HOME/$resource (may appear after game use)."
        fi
    done
fi

if (( tools_ready )); then
    compiler="$NWN_TOOLS/nwn_script_comp"
    if [[ ! -f $compiler || ! -x $compiler ]]; then
        fail "Compiler missing or not executable: $compiler. Run ./scripts/update-nwn-compiler.sh."
    else
        if command -v timeout >/dev/null 2>&1; then
            timeout 10 "$compiler" --help >/dev/null 2>&1
            compiler_status=$?
        else
            "$compiler" --help >/dev/null 2>&1
            compiler_status=$?
        fi
        if (( compiler_status == 0 )); then
            ok 'Configured compiler runs successfully (--help).'
        else
            fail "Compiler --help failed (exit $compiler_status). Check architecture/runtime compatibility."
        fi
    fi

    path_compiler=$(type -P nwn_script_comp || :)
    if [[ -z $path_compiler ]]; then
        fail 'nwn_script_comp is not on PATH. Run: export PATH="$NWN_TOOLS:$PATH"'
    elif [[ $path_compiler -ef $compiler ]]; then
        ok "PATH resolves the configured compiler: $path_compiler"
    else
        fail "PATH resolves a different compiler: $path_compiler. Prepend NWN_TOOLS to PATH."
    fi
fi

printf '\nChecks finished: %d error(s), %d warning(s).\n' "$errors" "$warnings"
if (( errors )); then
    exit 1
fi
printf 'Environment checks passed.\n'
