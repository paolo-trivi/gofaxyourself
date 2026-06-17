# Stable Contracts

These are the stable, public contracts for **GoFaxYourself v0.1**. Treat them
as the project's API. Changing them is a breaking change.

## CLI

- Runner script name: `gofax` (invoked as `./gofax`).
- `run-sipcmd-loop.sh` is a deprecated shim that forwards to `./gofax`.

## Docker

- Image name: `gofaxyourself:local`.
- Networking: `--net=host`.
- SIP engine: `baresip` (no PBX, no Asterisk, no FreeSWITCH).
- Audio payload is **mounted** into the container at `/audio/payload.wav`.

## Modes (stable identifiers)

| Mode     | Status               |
|----------|----------------------|
| `tape`   | Implemented, default |
| `script` | Reserved             |
| `brain`  | Reserved, disabled   |

See [MODES.md](MODES.md). Default mode is `tape`.

## Environment variables (stable names)

GoFax behavior:

| Variable                 | Default                            | Notes                          |
|--------------------------|------------------------------------|--------------------------------|
| `GOFAX_MODE`             | `tape`                             | Only `tape` runs in v0.1       |
| `GOFAX_LANGUAGE`         | `en`                               | Language pack code             |
| `GOFAX_PERSONA`          | `anti-call-center`                 | Persona / payload label        |
| `GOFAX_AUDIO_FILE`       | `./audio/it/anti-call-center.wav`  | **Source of truth** for Tape Mode |

`GOFAX_AUDIO_FILE` is the single source of truth for which WAV Tape Mode plays.
`GOFAX_LANGUAGE` and `GOFAX_PERSONA` are descriptive labels only — they do not
select the file. WAV files are gitignored (`*.wav`) and provided/generated
locally, with one exception: the bundled default `audio/it/anti-call-center.wav`
is whitelisted and ships. `./gofax` fails fast if `GOFAX_AUDIO_FILE` does not
exist.

SIP registration:

| Variable        | Default | Notes                                       |
|-----------------|---------|---------------------------------------------|
| `SIP_USERNAME`  | —       | Required. Auth username                     |
| `SIP_PASSWORD`  | —       | Required. Secret                            |
| `SIP_DOMAIN`    | —       | Required. The `@domain` in `user@domain`    |
| `SIP_SERVER`    | —       | Registrar / outbound proxy host             |
| `SIP_PORT`      | `5060`  | SIP signalling port                         |

Call loop:

| Variable                 | Default | Notes                                   |
|--------------------------|---------|-----------------------------------------|
| `CALL_DURATION_SECONDS`  | `0`     | `0` = stay registered until stopped     |
| `CALL_INTERVAL_SECONDS`  | `5`     | Pause between sessions                   |
| `AUDIO_FILE_SAMPLE_RATE` | `8000`  | Must match the WAV sample rate          |

Brain Mode (reserved, disabled by default — documented contract only):

| Variable               | Default | Notes                        |
|------------------------|---------|------------------------------|
| `GOFAX_LLM_ENABLED`    | `false` | Must stay `false` in v0.1    |
| `GOFAX_LLM_PROVIDER`   | —       | Reserved                     |
| `GOFAX_LLM_MODEL`      | —       | Reserved                     |
| `GOFAX_LLM_API_KEY`    | —       | Reserved                     |
| `GOFAX_TTS_ENABLED`    | `false` | Must stay `false` in v0.1    |
| `GOFAX_TTS_PROVIDER`   | —       | Reserved                     |
| `GOFAX_TTS_VOICE`      | —       | Reserved                     |

### Backward compatibility (deprecated)

Legacy variable names are still read as a fallback:

| Legacy name         | Preferred name        |
|---------------------|-----------------------|
| `SIP_USER`          | `SIP_USERNAME`        |
| `SIP_SERVER` (=domain) | `SIP_DOMAIN`       |
| `SIP_OUTBOUND_PROXY`| `SIP_SERVER` (proxy)  |
| `AUDIO_FILE`        | `GOFAX_AUDIO_FILE`    |

`DNS_SERVER` and `SIP_TRACE` remain available as optional extras.

## Language code format

- Lowercase ISO 639-1 two-letter codes: `en`, `it`, `es`, `fr`, `de`, `pt`.
- English (`en`) is the reference language. See [LANGUAGE_PACKS.md](LANGUAGE_PACKS.md).

## Persona naming format

- Lowercase, English-only, hyphenated identifiers (`kebab-case`).
- Reserved v0.1 personas:
  `confused-grandpa`, `tired-sysadmin`, `broken-fax`, `bureaucratic-loop`,
  `reverse-support`, `compliance-bot`, `hold-music-from-hell`, `angry-printer`.

## Audio pack path format

- `audio/<language>/<persona>.wav`
- Example: `audio/en/confused-grandpa.wav`.
- Recommended WAV format: mono, 8000 Hz, 16-bit PCM (SIP-friendly).

## Non-goals (explicit)

GoFaxYourself will **not** do these things:

- No outbound calls. No autodialing. No harassment automation.
- No PBX. No Asterisk. No FreeSWITCH.
- No database. No web UI. No dashboard.
- No cloud dependency (beyond your own SIP provider).
- No heavy runtime dependencies.
