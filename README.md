# default_nwn_mod

A starter/template project for building Neverwinter Nights: Enhanced Edition
modules on Ubuntu/Linux using an external editor and command-line tooling.

## Prerequisites

- Ubuntu/Linux
- Neverwinter Nights: Enhanced Edition (NWN:EE)
- Steam/Proton, if running the Windows build through Steam
- NVim or another editor
- `nwn_script_comp`, the NWScript compiler
- Git

### Install the compiler

`nwn_script_comp` is included in the prebuilt
[neverwinter.nim releases](https://github.com/niv/neverwinter.nim/releases).
Use the native Linux compiler even when the game runs through Proton.

For Ubuntu on an x86_64 machine (`uname -m` prints `x86_64`), install the
download/extraction tools, then download release 2.3.1 and install the compiler
into the example `NWN_TOOLS` directory:

```bash
sudo apt update
sudo apt install curl unzip

compiler_tmp="$(mktemp -d)"
curl --fail --location \
    --output "$compiler_tmp/neverwinter.zip" \
    "https://github.com/niv/neverwinter.nim/releases/download/2.3.1/neverwinter-x86_64-linux-gnu.zip"
unzip "$compiler_tmp/neverwinter.zip" nwn_script_comp -d "$compiler_tmp"
install -Dm755 "$compiler_tmp/nwn_script_comp" "$HOME/.local/bin/nwn_script_comp"

"$HOME/.local/bin/nwn_script_comp" --help
```

For ARM64 (`uname -m` prints `aarch64`), use the
`neverwinter-aarch64-linux-gnu.zip` asset instead. Other architectures may need
a source build; see the [upstream build instructions](https://github.com/niv/neverwinter.nim#development).
If you choose another installation directory, change the `install` destination
and set `NWN_TOOLS` in your local `.env` to match. Prebuilt releases do not
require Nim. Keep downloaded binaries outside this repository; load the project
environment below to make the compiler available through `PATH`.

### Update the compiler

The updater installs the latest stable release from
[neverwinter.nim](https://github.com/niv/neverwinter.nim/releases/latest) into
`NWN_TOOLS`. It also works for a first installation. After creating and editing
your local `.env`, run from the repository root in Bash or Zsh:

```bash
set -a
source .env
set +a

./scripts/update-nwn-compiler.sh
export PATH="$NWN_TOOLS:$PATH"
nwn_script_comp --help
```

To install a specific release instead:

```bash
./scripts/update-nwn-compiler.sh 2.3.1
```

The script requires `curl` and `unzip`, detects x86_64 or ARM64 Linux, and checks
the downloaded compiler before replacing the existing executable. It cleans up
temporary files and prints the installed path and resolved release URL. It uses
exported environment variables; it does not source `.env` or change shell startup
files. Run `./scripts/update-nwn-compiler.sh --help` for usage.

## Project Environment

This project uses a local `.env` file so configuration stays with the project
and does not require changes to global shell configuration such as `~/.bashrc`
or `~/.zshrc`. Each developer can use different Steam libraries, Proton prefixes,
and tool installation paths. Load the environment explicitly when working on
this project.

## Create your local .env

From the repository root, copy the example and edit your local configuration:

```bash
cp .env.example .env
nvim .env
```

- `NWN_TOOLS`: directory containing development executables such as `nwn_script_comp`.
- `NWN_ROOT`: root directory of the installed NWN:EE game files.
- `NWN_HOME`: NWN user-data directory, including the appropriate Proton prefix
  when using the Windows build.

Replace `XXXXXXXX` in `NWN_HOME` with your game's Steam app ID and adjust all
paths for your system. Keep values quoted to preserve spaces in paths.

## Finding NWN_ROOT

For a Steam installation, try:

```bash
find ~/.local/share/Steam/steamapps/common \
    -maxdepth 2 \
    -type d \
    -iname '*Neverwinter*' \
    2>/dev/null
```

`NWN_ROOT` points to the installed game files. If you use another Steam library,
search its `steamapps/common` directory instead.

## Finding NWN_HOME

For a Proton installation, try:

```bash
find ~/.local/share/Steam/steamapps/compatdata \
    -type d \
    -iname 'Neverwinter Nights' \
    2>/dev/null
```

The user-data directory may look similar to:

```text
~/.local/share/Steam/steamapps/compatdata/<APP_ID>/pfx/drive_c/users/steamuser/Documents/Neverwinter Nights
```

This directory typically contains user resources such as `modules`, `hak`,
`override`, `localvault`, and `logs`. Search your actual Steam library if it is
elsewhere. Launch the game once if the user-data directory has not been created.
For a native Linux installation, set `NWN_HOME` to that installation's user-data
directory instead of a Proton path.

## Loading the Environment

In Bash or Zsh, run from the repository root:

```bash
set -a
source .env
set +a
```

`set -a` causes variables defined in `.env` to be exported to child processes.
`set +a` turns automatic exporting off afterward.

Then temporarily prepend the tool directory to `PATH` for the current shell:

```bash
export PATH="$NWN_TOOLS:$PATH"
```

A shorter alternative, when you only need shell variables and do not need
automatic exporting, is:

```bash
source .env
export PATH="$NWN_TOOLS:$PATH"
```

In this alternative, newly defined NWN variables are available to the shell but
are not automatically exported to child processes. Use the preferred form when
build tools need to read those variables from their environment.

## Verify the Environment

Check the values and compiler discovery:

```bash
echo "$NWN_TOOLS"
echo "$NWN_ROOT"
echo "$NWN_HOME"

which nwn_script_comp
nwn_script_comp --help
```

Check that the directories exist and the compiler is executable:

```bash
test -d "$NWN_ROOT" && echo "NWN_ROOT OK"
test -d "$NWN_HOME" && echo "NWN_HOME OK"
test -x "$NWN_TOOLS/nwn_script_comp" && echo "Compiler OK"
```

If a check prints no confirmation, correct the corresponding path or install
the compiler before continuing.

## Typical Development Session

After creating your local `.env`:

```bash
cd default_nwn_mod

set -a
source .env
set +a

export PATH="$NWN_TOOLS:$PATH"

nvim .
```

Future build commands will use the project-local values loaded from `.env`.
Repeat the loading commands when starting a new shell; do not automatically
source `.env` from a shell startup file.

## Security and Git

- `.env` is local machine configuration and should not be committed. It is
  ignored by Git.
- `.env.example` should be committed so developers share the same configuration
  structure.
- `.env.example` must not contain passwords, tokens, API keys, or developer-specific
  paths. Keep generic examples using `$HOME` and placeholders.
- Each developer copies `.env.example` to `.env` and changes the values for
  their system.
- `source` executes shell code. Only load a `.env` file you trust.

## Next Steps

Later iterations of this template may add:

- `src/` for `.nss` files
- `build/`
- a Makefile
- automated NWScript compilation
- module packaging
- installation into `$NWN_HOME/modules`
- launching/testing NWN
- debug-console workflow
