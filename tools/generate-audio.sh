#!/usr/bin/env bash
#
# generate-audio.sh — optional, local, offline TTS for GoFaxYourself.
#
# Reads  scripts/<language>/<persona>.txt
# Writes audio/<language>/<persona>.wav   (mono, 8000 Hz, 16-bit PCM)
#
# Provider: espeak (or espeak-ng) ONLY. No cloud. No API keys.
# This is a DEVELOPER-SIDE asset build step. It is NOT a runtime dependency of
# ./gofax and is NOT installed by the Dockerfile.
#
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <language> <persona> [espeak-voice]

Example:
  $(basename "$0") en confused-grandpa
  $(basename "$0") it broken-fax it

Requires: espeak (or espeak-ng) and ffmpeg. Both are developer-side tools,
not needed to run ./gofax.
EOF
}

main() {
  if [[ "$#" -lt 2 ]]; then
    usage
    exit 2
  fi

  local language="$1"
  local persona="$2"
  local voice="${3:-${language}}"

  local repo_root script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "${script_dir}/.." && pwd)"
  cd "${repo_root}"

  local source_script="scripts/${language}/${persona}.txt"
  local output="audio/${language}/${persona}.wav"

  # Pick an espeak binary.
  local espeak_bin=""
  if command -v espeak >/dev/null 2>&1; then
    espeak_bin="espeak"
  elif command -v espeak-ng >/dev/null 2>&1; then
    espeak_bin="espeak-ng"
  else
    printf 'Error: espeak (or espeak-ng) not found.\n' >&2
    printf '       Install espeak to generate audio. This tool is optional and\n' >&2
    printf '       is NOT required to run ./gofax.\n' >&2
    exit 1
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    printf 'Error: ffmpeg not found. Install ffmpeg to normalize audio.\n' >&2
    printf '       This tool is optional and NOT required to run ./gofax.\n' >&2
    exit 1
  fi

  if [[ ! -f "${source_script}" ]]; then
    printf 'Error: source script not found: %s\n' "${source_script}" >&2
    exit 1
  fi

  local raw_wav
  raw_wav="$(mktemp -t gofax-tts.XXXXXX.wav)"
  trap 'rm -f "${raw_wav}"' EXIT

  printf '==> Synthesizing %s/%s with %s (voice: %s)\n' \
    "${language}" "${persona}" "${espeak_bin}" "${voice}" >&2
  "${espeak_bin}" -v "${voice}" -f "${source_script}" -w "${raw_wav}"

  printf '==> Normalizing to mono / 8000 Hz / 16-bit PCM\n' >&2
  if [[ -x "${script_dir}/normalize-audio.sh" ]]; then
    "${script_dir}/normalize-audio.sh" "${raw_wav}" "${output}"
  else
    mkdir -p "$(dirname "${output}")"
    ffmpeg -y -hide_banner -loglevel error \
      -i "${raw_wav}" \
      -ac 1 -ar 8000 -sample_fmt s16 -c:a pcm_s16le \
      "${output}"
  fi

  printf '==> Wrote %s\n\n' "${output}" >&2

  # Print a ready-to-paste provenance entry for audio/manifest.json.
  cat >&2 <<EOF
Add this entry to audio/manifest.json (under "assets"):

    {
      "language": "${language}",
      "persona": "${persona}",
      "source_script": "${source_script}",
      "provider": "${espeak_bin}",
      "generated_at": "$(date +%Y-%m-%d)",
      "output": "${output}",
      "sample_rate": 8000,
      "channels": 1,
      "sample_format": "s16",
      "redistribution": "verify-for-your-espeak-build",
      "notes": "Generated offline with ${espeak_bin}, voice '${voice}'. Confirm redistribution rights for your espeak/voice before publishing."
    }
EOF
}

main "$@"
