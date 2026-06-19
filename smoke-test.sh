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
note() { printf '  note %s\n' "$1"; }

check_file() {
  if [[ -f "$1" ]]; then ok "exists: $1"; else bad "missing: $1"; fi
}

printf '== files ==\n'
check_file "gofax"
check_file "gofax-start"
check_file "gofax-stop"
check_file "Dockerfile"
check_file "docker/baresip-entrypoint.sh"
check_file ".env.example"
check_file "README.md"
check_file "docs/CONTRACTS.md"
check_file "docs/MODES.md"
check_file "docs/LANGUAGE_PACKS.md"
check_file "docs/AUDIO_GENERATION.md"
check_file "docs/LOGGING.md"
check_file "docs/SAFETY.md"
check_file "LICENSE"
check_file "SECURITY.md"
check_file "CONTRIBUTING.md"
check_file "audio/manifest.json"
check_file "tools/generate-audio.sh"
check_file "tools/normalize-audio.sh"
check_file "docker/sip-cdr-logger.sh"

printf '== executables ==\n'
for exe in gofax gofax-start gofax-stop tools/generate-audio.sh tools/normalize-audio.sh docker/sip-cdr-logger.sh; do
  if [[ -x "${exe}" ]]; then ok "${exe} is executable"; else bad "${exe} is not executable"; fi
done

printf '== .env.example required vars ==\n'
for var in GOFAX_MODE GOFAX_LANGUAGE GOFAX_PERSONA GOFAX_AUDIO_FILE \
           SIP_USERNAME SIP_PASSWORD SIP_DOMAIN SIP_SERVER SIP_PORT \
           CALL_DURATION_SECONDS CALL_INTERVAL_SECONDS AUDIO_FILE_SAMPLE_RATE \
           GOFAX_LLM_ENABLED GOFAX_TTS_ENABLED \
           GOFAX_LOG_ENABLED GOFAX_LOG_HASH_PEPPER GOFAX_LOG_REDACT; do
  if grep -q "^${var}=" .env.example; then ok ".env.example has ${var}"; else bad ".env.example missing ${var}"; fi
done

printf '== default contracts ==\n'
grep -q "^GOFAX_MODE=tape$" .env.example && ok "default mode is tape" || bad "default mode is not tape"
grep -q "^AUDIO_FILE_SAMPLE_RATE=8000$" .env.example && ok "sample rate default is 8000" || bad "sample rate default is not 8000"
grep -q 'gofaxyourself:local' gofax && ok "docker image name is gofaxyourself:local" || bad "docker image name not found in gofax"
grep -q '/audio/payload.wav' docker/baresip-entrypoint.sh && ok "container audio path is /audio/payload.wav" || bad "container audio path not neutralized"
grep -q '^GOFAX_LOG_ENABLED=false$' .env.example && ok "logging defaults to off" || bad "logging default is not off"
grep -qE '^logs/$' .gitignore && grep -qE '^\*\.ndjson$' .gitignore && ok "call logs are gitignored" || bad "call logs not gitignored"

printf '== default audio file ==\n'
# WAVs are gitignored and provided locally, so a clean clone has NO audio.
# Normal mode: a missing default audio file is a NOTE, not a failure.
# Strict mode (GOFAX_SMOKE_REQUIRE_AUDIO=1): a missing default FAILS.
default_audio="$(grep -E '^GOFAX_AUDIO_FILE=' .env.example | head -1 | cut -d= -f2-)"
require_audio="${GOFAX_SMOKE_REQUIRE_AUDIO:-0}"
if [[ -z "${default_audio}" ]]; then
  ok "no active default GOFAX_AUDIO_FILE in .env.example"
elif [[ -f "${default_audio}" ]]; then
  ok "default GOFAX_AUDIO_FILE exists: ${default_audio}"
elif [[ "${require_audio}" == "1" ]]; then
  bad "[strict] default GOFAX_AUDIO_FILE missing: ${default_audio}"
else
  note "default audio not present (expected on a clean clone): ${default_audio}"
  note "generate/provide it locally, or enforce with GOFAX_SMOKE_REQUIRE_AUDIO=1"
fi
# Note: per-persona WAVs are NOT required — only the default above (strict mode).

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
# Scope: committed/public files only. Skip gitignored runtime dirs (logs/ holds
# real numbers by design — see docs/LOGGING.md) and the git internals.
stale="$(grep -rniE 'windtre|segreteria|ferie\.wav|segreteria-baresip' \
  --exclude='.env' --exclude='smoke-test.sh' \
  --exclude-dir='logs' --exclude-dir='.git' . 2>/dev/null || true)"
if [[ -z "${stale}" ]]; then
  ok "no stale references found"
else
  bad "stale references found:"
  printf '%s\n' "${stale}" | sed 's/^/       /'
fi

printf '\n== summary: %d passed, %d failed ==\n' "${pass}" "${fail}"
[[ "${fail}" -eq 0 ]]
