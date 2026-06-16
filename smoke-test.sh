#!/usr/bin/env bash
#
# GoFaxYourself — minimal smoke test.
# Checks repo structure and public contracts. No framework, just grep + test.
#
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }

check_file() {
  if [[ -f "$1" ]]; then ok "exists: $1"; else bad "missing: $1"; fi
}

printf '== files ==\n'
check_file "gofax"
check_file "Dockerfile"
check_file "docker/baresip-entrypoint.sh"
check_file ".env.example"
check_file "README.md"
check_file "docs/CONTRACTS.md"
check_file "docs/MODES.md"
check_file "docs/LANGUAGE_PACKS.md"
check_file "docs/AUDIO_GENERATION.md"
check_file "docs/SAFETY.md"
check_file "LICENSE"
check_file "SECURITY.md"
check_file "CONTRIBUTING.md"
check_file "audio/manifest.json"
check_file "tools/generate-audio.sh"
check_file "tools/normalize-audio.sh"

printf '== executables ==\n'
for exe in gofax tools/generate-audio.sh tools/normalize-audio.sh; do
  if [[ -x "${exe}" ]]; then ok "${exe} is executable"; else bad "${exe} is not executable"; fi
done

printf '== .env.example required vars ==\n'
for var in GOFAX_MODE GOFAX_LANGUAGE GOFAX_PERSONA GOFAX_AUDIO_FILE \
           SIP_USERNAME SIP_PASSWORD SIP_DOMAIN SIP_SERVER SIP_PORT \
           CALL_DURATION_SECONDS CALL_INTERVAL_SECONDS AUDIO_FILE_SAMPLE_RATE \
           GOFAX_LLM_ENABLED GOFAX_TTS_ENABLED; do
  if grep -q "^${var}=" .env.example; then ok ".env.example has ${var}"; else bad ".env.example missing ${var}"; fi
done

printf '== default contracts ==\n'
grep -q "^GOFAX_MODE=tape$" .env.example && ok "default mode is tape" || bad "default mode is not tape"
grep -q "^AUDIO_FILE_SAMPLE_RATE=8000$" .env.example && ok "sample rate default is 8000" || bad "sample rate default is not 8000"
grep -q 'gofaxyourself:local' gofax && ok "docker image name is gofaxyourself:local" || bad "docker image name not found in gofax"
grep -q '/audio/payload.wav' docker/baresip-entrypoint.sh && ok "container audio path is /audio/payload.wav" || bad "container audio path not neutralized"

printf '== default audio file ==\n'
# If .env.example sets a default GOFAX_AUDIO_FILE, that file MUST exist.
default_audio="$(grep -E '^GOFAX_AUDIO_FILE=' .env.example | head -1 | cut -d= -f2-)"
if [[ -n "${default_audio}" ]]; then
  if [[ -f "${default_audio}" ]]; then
    ok "default GOFAX_AUDIO_FILE exists: ${default_audio}"
  else
    bad "default GOFAX_AUDIO_FILE is set but missing: ${default_audio}"
  fi
else
  ok "no active default GOFAX_AUDIO_FILE (user must provide one)"
fi
# Note: per-persona WAVs are NOT required — only the default above.

printf '== script packs ==\n'
check_file "scripts/manifest.json"
languages="en it es fr de pt"
personas="confused-grandpa tired-sysadmin broken-fax bureaucratic-loop reverse-support compliance-bot hold-music-from-hell angry-printer"
for lang in ${languages}; do
  for persona in ${personas}; do
    script="scripts/${lang}/${persona}.txt"
    if [[ ! -f "${script}" ]]; then
      bad "missing script: ${script}"
      continue
    fi
    # Count non-empty (non-whitespace-only) lines.
    lines="$(grep -cve '^[[:space:]]*$' "${script}")"
    if [[ "${lines}" -ge 20 ]]; then
      ok "${script} (${lines} lines)"
    else
      bad "${script} has only ${lines} non-empty lines (need >= 20)"
    fi
  done
done
# Note: audio files are NOT required for every persona yet (text-first).

printf '== no stale project names (outside compat notes) ==\n'
# Old project identifiers must not leak into public files.
stale="$(grep -rniE 'windtre|segreteria|ferie\.wav|segreteria-baresip' \
  --exclude='.env' --exclude='smoke-test.sh' . 2>/dev/null || true)"
if [[ -z "${stale}" ]]; then
  ok "no stale references found"
else
  bad "stale references found:"
  printf '%s\n' "${stale}" | sed 's/^/       /'
fi

printf '\n== summary: %d passed, %d failed ==\n' "${pass}" "${fail}"
[[ "${fail}" -eq 0 ]]
