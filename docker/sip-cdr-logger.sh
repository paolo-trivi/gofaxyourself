#!/usr/bin/env bash
#
# GoFaxYourself — SIP CDR logger.
#
# Reads baresip stdout/stderr on STDIN, mirrors it verbatim to a raw artifact
# log, and turns each inbound call into one structured NDJSON record (an
# "extended CDR", a pragmatic subset of logging_and_audit_voip.md).
#
# It is a passive observer: it never places calls, never blocks baresip's
# output, and writes only to ${LOG_DIR}. Lines it does not understand are still
# preserved verbatim in the raw log, so nothing is ever lost.
#
# Privacy: the caller id is stored BOTH hashed (sha256 + local pepper, for
# correlation/counting) AND — by default — in clear text. Set GOFAX_LOG_REDACT
# to drop the clear-text field. Logs hold real numbers: they are gitignored and
# must never be committed.
#
set -uo pipefail

readonly LOG_DIR="${LOG_DIR:-/logs}"
readonly HASH_PEPPER="${GOFAX_LOG_HASH_PEPPER:-}"
readonly REDACT="${GOFAX_LOG_REDACT:-false}"
readonly SAMPLE_RATE="${AUDIO_FILE_SAMPLE_RATE:-}"
readonly TRACE_ENABLED="${GOFAX_LOG_TRACE:-false}"
readonly PLAYBACK_FILE="${GOFAX_AUDIO_FILE:-payload.wav}"

readonly RAW_FILE="${LOG_DIR}/baresip-raw-$(date -u +%Y%m%dT%H%M%SZ).log"
readonly CDR_FILE="${LOG_DIR}/cdr-$(date -u +%Y-%m-%d).ndjson"
readonly RAW_REF="$(basename "${RAW_FILE}")"

# --- helpers ---------------------------------------------------------------

is_true() {
  [[ "${1:-}" =~ ^(1|true|yes|on)$ ]]
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

now_epoch() {
  date -u +%s
}

# Escape a string for safe inclusion inside a JSON double-quoted value.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  printf '%s' "${s}"
}

# Emit a JSON value: `null` when empty, otherwise a quoted escaped string.
jstr() {
  if [[ -z "${1:-}" ]]; then
    printf 'null'
  else
    printf '"%s"' "$(json_escape "$1")"
  fi
}

# Emit a JSON value: the raw integer when set, otherwise `null`.
jnum() {
  if [[ -z "${1:-}" ]]; then
    printf 'null'
  else
    printf '%s' "$1"
  fi
}

jbool() {
  if is_true "$1"; then printf 'true'; else printf 'false'; fi
}

hash_caller() {
  local caller="$1"
  [[ -z "${caller}" ]] && return 0
  printf 'sha256:%s' "$(printf '%s' "${HASH_PEPPER}${caller}" | sha256sum | cut -d' ' -f1)"
}

# --- per-call state --------------------------------------------------------

reset_call() {
  in_call="false"
  session_id=""
  ts_start=""
  ts_answer=""
  epoch_start=""
  epoch_answer=""
  caller_raw=""
  caller_display=""
  callee=""
  status_code=""
  status_reason=""
  user_agent=""
  call_id=""
}

# Per-message (SIP trace block) scratch state.
reset_block() {
  b_active="false"
  b_kind=""          # req | resp
  b_method=""        # request method
  b_code=""          # response status code
  b_reason=""        # response reason phrase
  b_cseq_method=""   # dialog method from CSeq (present in req and resp)
  b_callid=""
  b_from_uri=""
  b_from_disp=""
  b_to_uri=""
  b_ua=""
}

new_session_id() {
  # Best-effort uuid-ish id without extra deps.
  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    printf '%s-%s' "$(now_epoch)" "${RANDOM}${RANDOM}"
  fi
}

start_call() {
  local callid="$1"
  reset_call
  in_call="true"
  call_id="${callid}"
  session_id="$(new_session_id)"
  ts_start="$(now_iso)"
  epoch_start="$(now_epoch)"
}

emit_cdr() {
  [[ "${in_call}" != "true" ]] && return 0
  local ts_end epoch_end duration=""
  ts_end="$(now_iso)"
  epoch_end="$(now_epoch)"
  if [[ -n "${epoch_start}" ]]; then
    duration=$((epoch_end - epoch_start))
  fi

  # Open (and create) the CDR file only once we actually have a call to write,
  # so a run with zero calls leaves no empty file behind.
  {
    printf '{'
    printf '"session_id":%s,' "$(jstr "${session_id}")"
    printf '"ts_start":%s,' "$(jstr "${ts_start}")"
    printf '"ts_answer":%s,' "$(jstr "${ts_answer}")"
    printf '"ts_end":%s,' "$(jstr "${ts_end}")"
    printf '"duration_s":%s,' "$(jnum "${duration}")"
    printf '"direction":"inbound",'
    printf '"caller":{"raw":%s,"hash":%s,"display":%s},' \
      "$(if is_true "${REDACT}"; then printf 'null'; else jstr "${caller_raw}"; fi)" \
      "$(jstr "$(hash_caller "${caller_raw}")")" \
      "$(jstr "${caller_display}")"
    printf '"callee":%s,' "$(jstr "${callee}")"
    printf '"final_status":{"code":%s,"reason":%s},' \
      "$(jnum "${status_code}")" "$(jstr "${status_reason}")"
    printf '"sip":{"user_agent":%s,"call_id":%s},' \
      "$(jstr "${user_agent}")" "$(jstr "${call_id}")"
    printf '"node":{"container_id":%s,"host_network":true,"trace_enabled":%s},' \
      "$(jstr "$(hostname)")" "$(jbool "${TRACE_ENABLED}")"
    printf '"audio":{"playback_file":%s,"sample_rate":%s},' \
      "$(jstr "$(basename "${PLAYBACK_FILE}")")" "$(jnum "${SAMPLE_RATE}")"
    printf '"raw_ref":%s' "$(jstr "${RAW_REF}")"
    printf '}\n'
  } >>"${CDR_FILE}"
}

# --- SIP trace parsing -----------------------------------------------------
#
# baresip is launched with `-s` whenever logging is on, so every SIP message is
# dumped as a block:
#
#   #
#   UDP <src_ip>:<port> -> <dst_ip>:<port>
#   INVITE sip:you@dom SIP/2.0        (request)   | SIP/2.0 200 OK  (response)
#   From: "Caller" <sip:+39...@dom>;tag=...
#   To: <sip:you@dom>
#   Call-ID: ...
#   CSeq: 1 INVITE
#   User-Agent: ...
#   <blank line>
#
# The CDR is anchored to these messages (deterministic), not to baresip's
# human-readable menu lines. We only track the INVITE dialog; REGISTER /
# OPTIONS / SUBSCRIBE etc. are ignored. baresip caps concurrent calls at 1,
# so a single active-call state is enough.

first_uri() {
  grep -oE 'sip:[^ >;"]+' <<<"$1" | head -n1
}

# Decide what a just-completed SIP message means for the active call.
handle_block() {
  local dialog="${b_cseq_method:-${b_method}}"
  case "${dialog}" in
    INVITE|BYE|CANCEL|ACK) ;;
    *) return 0 ;;   # not part of a call dialog
  esac

  if [[ "${b_kind}" == "req" ]]; then
    case "${b_method}" in
      INVITE)
        # New inbound call (From = caller, To = us).
        if [[ "${in_call}" != "true" || "${call_id}" != "${b_callid}" ]]; then
          start_call "${b_callid}"
          caller_raw="${b_from_uri#sip:}"
          caller_display="${b_from_disp}"
          callee="${b_to_uri}"
          user_agent="${b_ua}"
        fi
        ;;
      BYE)
        if [[ "${in_call}" == "true" && "${b_callid}" == "${call_id}" ]]; then
          [[ -z "${status_code}" ]] && { status_code="200"; status_reason="OK"; }
          emit_cdr
          reset_call
        fi
        ;;
      CANCEL)
        if [[ "${in_call}" == "true" && "${b_callid}" == "${call_id}" && -z "${ts_answer}" ]]; then
          status_code="487"; status_reason="Request Terminated"
          emit_cdr
          reset_call
        fi
        ;;
    esac
  elif [[ "${b_kind}" == "resp" && "${b_cseq_method}" == "INVITE" \
          && "${in_call}" == "true" && "${b_callid}" == "${call_id}" ]]; then
    case "${b_code}" in
      100|180|181|182|183) ;;                       # provisional: ignore
      2[0-9][0-9])
        if [[ -z "${ts_answer}" ]]; then
          ts_answer="$(now_iso)"; epoch_answer="$(now_epoch)"
        fi
        status_code="${b_code}"; status_reason="${b_reason}"
        ;;
      [3-6][0-9][0-9])                              # final failure: call ends
        status_code="${b_code}"; status_reason="${b_reason}"
        emit_cdr
        reset_call
        ;;
    esac
  fi
}

# Accumulate header fields of the SIP message currently being read.
accumulate_block_line() {
  local line="$1"
  if [[ -z "${b_kind}" ]]; then
    if [[ "${line}" =~ ^[A-Z]+\ (sip|sips|tel):[^[:space:]]+\ SIP/2\.0$ ]]; then
      b_kind="req"; b_method="${line%% *}"; return 0
    elif [[ "${line}" =~ ^SIP/2\.0\ ([0-9]{3})\ (.*)$ ]]; then
      b_kind="resp"; b_code="${BASH_REMATCH[1]}"; b_reason="${BASH_REMATCH[2]}"; return 0
    fi
  fi
  case "${line}" in
    "From:"*|"f:"*)  [[ -z "${b_from_uri}" ]] && {
                       b_from_uri="$(first_uri "${line}")"
                       b_from_disp="$(sed -E 's/^[^:]+:[[:space:]]*//; s/[[:space:]]*<?sips?:.*//; s/^"//; s/"$//' <<<"${line}")"
                     } ;;
    "To:"*|"t:"*)    [[ -z "${b_to_uri}" ]] && b_to_uri="$(first_uri "${line}")" ;;
    "Call-ID:"*|"i:"*)
                     [[ -z "${b_callid}" ]] && b_callid="$(sed -E 's/^[^:]+:[[:space:]]*//' <<<"${line}")" ;;
    "CSeq:"*)        b_cseq_method="$(awk '{print $3}' <<<"${line}")" ;;
    "User-Agent:"*)  [[ -z "${b_ua}" ]] && b_ua="$(sed -E 's/^[^:]+:[[:space:]]*//' <<<"${line}")" ;;
  esac
}

parse_line() {
  local line="$1"
  # Strip ANSI colour codes baresip emits around trace blocks, and the CR from
  # SIP's CRLF line endings (the raw artifact log keeps the bytes verbatim).
  line="$(printf '%s' "${line}" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g; s/\r//g')"

  if [[ "${line}" =~ ^(UDP|TCP|TLS)\ [0-9a-fA-F:.]+:[0-9]+\ -\>\ [0-9a-fA-F:.]+:[0-9]+ ]]; then
    # New SIP message block: finalize any previous one, then start fresh.
    [[ "${b_active}" == "true" ]] && handle_block
    reset_block
    b_active="true"
    return 0
  fi

  if [[ "${b_active}" == "true" ]]; then
    if [[ -z "${line}" ]]; then
      # Blank line ends the header section (and the message, for us).
      handle_block
      reset_block
    else
      accumulate_block_line "${line}"
    fi
  fi
}

# --- main ------------------------------------------------------------------

main() {
  mkdir -p "${LOG_DIR}"
  reset_call
  reset_block

  local line
  while IFS= read -r line; do
    # 1) Mirror verbatim to stdout so `docker logs` / the terminal still work.
    printf '%s\n' "${line}"
    # 2) Preserve verbatim in the raw artifact log.
    printf '%s\n' "${line}" >>"${RAW_FILE}"
    # 3) Update the structured CDR state machine.
    parse_line "${line}"
  done

  # Finalize a pending message and flush a call still open when baresip exited.
  [[ "${b_active:-false}" == "true" ]] && handle_block
  emit_cdr
}

main "$@"
