#!/usr/bin/env bash
#
# GoFaxYourself — baresip entrypoint.
# Writes a minimal baresip config + account, then runs baresip in auto-answer
# mode and plays the mounted WAV payload to whoever calls in.
#
set -euo pipefail

readonly CONFIG_DIR="/tmp/baresip"
readonly AUDIO_PATH="/audio/payload.wav"
readonly DEFAULT_SIP_PORT="5060"
readonly DEFAULT_CALL_DURATION_SECONDS="0"
readonly DEFAULT_AUDIO_FILE_SAMPLE_RATE="8000"

require_value() {
  local label="$1" value="$2"
  if [[ -z "${value}" ]]; then
    printf 'Error: required SIP value is missing: %s\n' "${label}" >&2
    exit 1
  fi
}

validate_seconds() {
  local label="$1" value="$2"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    printf 'Error: %s must be a non-negative integer.\n' "${label}" >&2
    exit 1
  fi
}

resolve_sip_settings() {
  # Public contract: SIP_USERNAME / SIP_DOMAIN / SIP_SERVER (proxy) / SIP_PORT.
  # Backward compatibility with the legacy layout where SIP_SERVER held the
  # domain and SIP_OUTBOUND_PROXY held the registrar/proxy host.
  sip_username="${SIP_USERNAME:-${SIP_USER:-}}"
  sip_port="${SIP_PORT:-${DEFAULT_SIP_PORT}}"

  if [[ -n "${SIP_DOMAIN:-}" ]]; then
    sip_domain="${SIP_DOMAIN}"
    sip_proxy="${SIP_SERVER:-${SIP_OUTBOUND_PROXY:-}}"
  else
    # Legacy layout.
    sip_domain="${SIP_SERVER:-}"
    sip_proxy="${SIP_OUTBOUND_PROXY:-}"
  fi
}

write_baresip_config() {
  local auth_user="${SIP_AUTH_USER:-${sip_username}}"
  local account_params="auth_user=${auth_user};auth_pass=${SIP_PASSWORD};answermode=auto;audio_codecs=pcma,pcmu"

  if [[ -n "${sip_proxy}" ]]; then
    account_params="${account_params};outbound=\"sip:${sip_proxy}:${sip_port};transport=udp\""
  fi

  mkdir -p "${CONFIG_DIR}"
  chmod 700 "${CONFIG_DIR}"

  cat >"${CONFIG_DIR}/config" <<EOF
poll_method		epoll

sip_cafile		/etc/ssl/certs/ca-certificates.crt
sip_verify_server	no
sip_trans_def		udp
call_local_timeout	120
call_max_calls		1

$(if [[ -n "${DNS_SERVER:-}" ]]; then printf 'dns_server\t\t%s\n' "${DNS_SERVER}"; fi)

audio_player		aufile,/tmp/received.wav
audio_source		aufile,${AUDIO_PATH}
audio_alert		aufile,${AUDIO_PATH}
ausrc_format		s16
auplay_format		s16
auenc_format		s16
audec_format		s16
audio_buffer		20-160

rtp_tos			184
rtcp_mux		no
jitter_buffer_type	fixed
jitter_buffer_delay	5-10

module_path		/usr/lib/baresip/modules
module			g711.so
module			aufile.so
module_tmp		account.so
module_app		menu.so

file_ausrc		aufile
file_srate		${AUDIO_FILE_SAMPLE_RATE}
file_channels		1
EOF

  cat >"${CONFIG_DIR}/accounts" <<EOF
<sip:${sip_username}@${sip_domain};transport=udp>;${account_params}
EOF

  chmod 600 "${CONFIG_DIR}/config" "${CONFIG_DIR}/accounts"
}

main() {
  local baresip_args=(-4 -f "${CONFIG_DIR}")

  CALL_DURATION_SECONDS="${CALL_DURATION_SECONDS:-${DEFAULT_CALL_DURATION_SECONDS}}"
  AUDIO_FILE_SAMPLE_RATE="${AUDIO_FILE_SAMPLE_RATE:-${DEFAULT_AUDIO_FILE_SAMPLE_RATE}}"

  resolve_sip_settings

  require_value "SIP_USERNAME" "${sip_username}"
  require_value "SIP_PASSWORD" "${SIP_PASSWORD:-}"
  require_value "SIP_DOMAIN" "${sip_domain}"
  validate_seconds "CALL_DURATION_SECONDS" "${CALL_DURATION_SECONDS}"
  validate_seconds "AUDIO_FILE_SAMPLE_RATE" "${AUDIO_FILE_SAMPLE_RATE}"

  if [[ ! -f "${AUDIO_PATH}" ]]; then
    printf 'Error: audio payload not found in container: %s\n' "${AUDIO_PATH}" >&2
    exit 1
  fi

  write_baresip_config

  if [[ "${CALL_DURATION_SECONDS}" -gt 0 ]]; then
    baresip_args+=(-t "${CALL_DURATION_SECONDS}")
  fi

  if [[ "${SIP_TRACE:-}" == "1" || "${SIP_TRACE:-}" == "true" || "${SIP_TRACE:-}" == "yes" ]]; then
    baresip_args+=(-s)
  fi

  exec baresip "${baresip_args[@]}"
}

main "$@"
