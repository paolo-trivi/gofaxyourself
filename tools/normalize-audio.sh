#!/usr/bin/env bash
#
# normalize-audio.sh — force any audio file into the SIP-friendly WAV format:
#   WAV container, mono, 8000 Hz, 16-bit PCM (pcm_s16le).
#
# Optional, developer-side only. Requires ffmpeg. NOT a runtime dependency of
# ./gofax and NOT installed by the Dockerfile.
#
set -euo pipefail

usage() {
  printf 'Usage: %s <input-audio> <output.wav>\n' "$(basename "$0")" >&2
}

main() {
  if [[ "$#" -ne 2 ]]; then
    usage
    exit 2
  fi

  local input="$1" output="$2"

  if ! command -v ffmpeg >/dev/null 2>&1; then
    printf 'Error: ffmpeg not found. Install ffmpeg to normalize audio.\n' >&2
    printf '       (This is a developer-side tool, not required to run ./gofax.)\n' >&2
    exit 1
  fi

  if [[ ! -f "${input}" ]]; then
    printf 'Error: input file not found: %s\n' "${input}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${output}")"

  ffmpeg -y -hide_banner -loglevel error \
    -i "${input}" \
    -ac 1 -ar 8000 -sample_fmt s16 -c:a pcm_s16le \
    "${output}"

  printf 'Normalized -> %s (mono, 8000 Hz, 16-bit PCM)\n' "${output}" >&2
}

main "$@"
