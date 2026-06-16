#!/usr/bin/env bash
#
# Deprecated: this runner was renamed to ./gofax.
# Kept as a thin shim for backward compatibility. Please use ./gofax.
#
set -euo pipefail

printf 'Note: run-sipcmd-loop.sh is deprecated — forwarding to ./gofax\n' >&2

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${script_dir}/gofax" "$@"
