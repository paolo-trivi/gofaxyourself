```
  +-------------------------------------------+
  |   ___      ___          GoFaxYourself     |
  |  / __|___ | __|_ ___ __  __               |
  | | (_ / _ \| _/ _` \ \/ / |_ |  [.....]    |
  |  \___\___/|_|\__,_/_/\_\__/    | fax |     |
  |                               =========    |
  +-------------------------------------------+
```

# GoFaxYourself

**A tiny SIP honeypot that answers spam calls so you don't have to.**

> No cloud. No dashboard. No mercy.
> Just baresip, Docker, WAV files, and optional AI-powered nonsense.

Spammers call your number. GoFax picks up, auto-answers, and plays them a
pre-recorded tape of a confused grandpa (or a broken fax, or an angry printer).
You do nothing. They waste their time. That's the whole product.

**Pre-recorded by default. LLM-powered only if you enjoy burning tokens for justice.**

---

## What it is

A minimal Docker wrapper around [`baresip`](https://github.com/baresip/baresip).
It registers to your SIP provider, auto-answers inbound calls, and plays a WAV.

**No PBX. No database. No web UI. No bullshit.**

- ☎️  Inbound SIP auto-answer only
- 📼 Pre-recorded WAV files by default (Tape Mode)
- 🌍 English-first, multilingual by design
- 🐳 Docker-first, terminal-first, old-skool
- 🤖 Optional LLM/TTS chaos later — disabled by default, not required

This is **not** an enterprise anti-spam platform. It's a shell script, a
Dockerfile, and some WAV files.

## Quick start

```bash
cp .env.example .env
nano .env          # set SIP_USERNAME, SIP_PASSWORD, SIP_DOMAIN, SIP_SERVER

./gofax            # works out of the box: plays the bundled Italian default
```

That's it. First run builds the local image `gofaxyourself:local` from
`debian:trixie-slim` and installs `baresip-core`. Stop with `Ctrl+C`.

GoFax ships with **one** bundled default payload —
`audio/it/anti-call-center.wav` — so a clean clone works immediately. Every
**other** WAV is intentionally **ignored by git** (`*.wav`): you generate or
drop those in locally. `./gofax` **fails fast** if the audio file set in your
`.env` does not exist. Swap the default for any persona:

```bash
tools/generate-audio.sh it broken-fax    # needs espeak + ffmpeg (optional)
# then set GOFAX_AUDIO_FILE=./audio/it/broken-fax.wav in .env
```

## Modes

| Mode     | What                                        | Status               |
|----------|---------------------------------------------|----------------------|
| `tape`   | Play pre-recorded WAV files                  | ✅ default            |
| `script` | Local randomized snippets                    | 🔒 reserved          |
| `brain`  | Optional LLM + TTS chaos                      | 🔒 reserved, disabled |

**Tape Mode** is the whole point: offline, no API keys, just WAV files.
**Script Mode** and **Brain Mode** are documented contracts only — see
[docs/MODES.md](docs/MODES.md). Brain Mode (LLM/TTS) is **disabled by default**
and not wired to any provider in v0.1. Setting `GOFAX_LLM_ENABLED=true` today
just makes GoFax politely refuse.

## Language packs

English-first, multilingual by design. Audio lives at:

```
scripts/<language>/<persona>.txt   <- the funny lines (committed)
audio/it/anti-call-center.wav       <- the one bundled default (committed)
audio/<language>/<persona>.wav      <- other voices you generate (gitignored, local)
```

Initial languages: `en` `it` `es` `fr` `de` `pt`. We ship **48 text script
packs** (8 personas × 6 languages) plus one bundled Italian default payload;
all other audio is generated locally and not shipped.
Recommended WAV format: **mono, 8000 Hz, 16-bit PCM** (SIP-friendly).
Add your own — see [docs/LANGUAGE_PACKS.md](docs/LANGUAGE_PACKS.md).

## Generating audio

GoFaxYourself **ships text scripts, not voices.** Audio generation is
**optional** and happens on your machine — the runtime stays tiny and never
calls a TTS service.

```bash
# Optional, developer-side. Needs espeak + ffmpeg (NOT needed to run ./gofax).
tools/generate-audio.sh en confused-grandpa
```

This reads `scripts/en/confused-grandpa.txt`, synthesizes offline speech with
espeak, and writes a SIP-friendly `audio/en/confused-grandpa.wav` (mono,
8000 Hz, 16-bit PCM). `espeak`/`ffmpeg` are never installed by the Dockerfile
and are not dependencies of `./gofax`.

Generated audio needs **provenance**: every WAV is recorded in
[`audio/manifest.json`](audio/manifest.json) with its source and redistribution
status. Many TTS voices forbid redistribution, so **when in doubt, commit the
script, not the voice.** Details: [docs/AUDIO_GENERATION.md](docs/AUDIO_GENERATION.md).

## Personas

English-only ids: `confused-grandpa`, `tired-sysadmin`, `broken-fax`,
`bureaucratic-loop`, `reverse-support`, `compliance-bot`,
`hold-music-from-hell`, `angry-printer`.

## Configuration

All config lives in `.env` (copied from `.env.example`). The essentials:

```bash
GOFAX_MODE=tape
GOFAX_AUDIO_FILE=./audio/en/confused-grandpa.wav

SIP_USERNAME=your-account
SIP_PASSWORD=your-secret
SIP_DOMAIN=sip.example.net
SIP_SERVER=sip.example.net
SIP_PORT=5060
```

Full reference: [docs/CONTRACTS.md](docs/CONTRACTS.md).

> Legacy variable names (`SIP_USER`, `SIP_OUTBOUND_PROXY`, `AUDIO_FILE`, …)
> still work as a fallback, but the names above are the supported contract.

## Docs

- [docs/CONTRACTS.md](docs/CONTRACTS.md) — stable env vars, modes, paths, non-goals
- [docs/MODES.md](docs/MODES.md) — Tape / Script / Brain
- [docs/LANGUAGE_PACKS.md](docs/LANGUAGE_PACKS.md) — how to add a language
- [docs/AUDIO_GENERATION.md](docs/AUDIO_GENERATION.md) — optional TTS + audio provenance
- [docs/SAFETY.md](docs/SAFETY.md) — inbound-only, no outbound, your responsibilities
- [CONTRIBUTING.md](CONTRIBUTING.md) — add language packs and persona scripts
- [SECURITY.md](SECURITY.md) — never commit secrets; responsible disclosure

## Safety

GoFax **only answers inbound calls**. It never places outbound calls, never
autodials, and is not for harassment. The default purpose is defensive
spam-call handling. You are responsible for complying with local laws and your
telecom provider's terms. Read [docs/SAFETY.md](docs/SAFETY.md).

## Requirements

- Docker
- A SIP account that accepts inbound calls
- A sense of humor

## Maintainer

Built and maintained by [@paolo-trivi](https://github.com/paolo-trivi).
Bug reports and language packs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Code, shell scripts, and text script packs are [MIT licensed](LICENSE).

**Audio is not covered by MIT.** Only one WAV ships:
`audio/it/anti-call-center.wav`, the project owner's own Italian demo
(project-owned, redistributable as the bundled default). Every other WAV is
gitignored — you generate or provide it locally, and any audio you publish must
carry its own provenance and redistribution rights in
[audio/manifest.json](audio/manifest.json). When in doubt, commit the script,
not the voice.
