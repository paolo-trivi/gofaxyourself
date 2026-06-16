# Contributing to GoFaxYourself

Old-skool rules. Keep it tiny. Keep it funny. Keep it safe.

The runtime is just baresip + Docker + WAV files. Most contributions are
**text** (scripts) or **docs** — not code, and almost never binary audio.

## Add a language pack

1. Pick a language code (lowercase ISO 639-1: `en`, `it`, `es`, `fr`, `de`,
   `pt`, ...).
2. Localize the personas you want under `scripts/<language>/<persona>.txt`.
3. Update `scripts/manifest.json`.
4. Run `./smoke-test.sh`.

See [docs/LANGUAGE_PACKS.md](docs/LANGUAGE_PACKS.md) for the full layout.

## Add a persona script

1. Start from the canonical English file: `scripts/en/<persona>.txt`.
2. Keep persona ids in English `kebab-case` (same filename in every language).
3. Write exactly **20 short lines**, one idea per line, each usable as a
   standalone TTS prompt. Keep them short — they become phone audio.
4. Plain UTF-8. **No markdown** inside script files.
5. English is canonical; other languages are natural localizations, not literal
   machine translations.

## Safety & style rules

Keep it public-GitHub-safe. Yes to: surreal bureaucracy, fake troubleshooting,
fax/printer jokes, sysadmin exhaustion, compliance loops, absurd form-filling.

No to: hate speech, threats, slurs, targeted harassment, sexual content,
instructions to commit fraud or evade law enforcement, real company names, real
phone numbers, personal data, or profanity as the main joke.

This project is **inbound-only and defensive**. Nothing here should help place
outbound calls, autodial, or harass. See [docs/SAFETY.md](docs/SAFETY.md).

## Audio assets require provenance

Text first. **When in doubt, commit the script, not the voice.**

If you do contribute a WAV:

- It must be mono, 8000 Hz, 16-bit PCM.
- It must have **clear redistribution rights** (a license that allows it).
- It must be recorded in `audio/manifest.json` with full provenance.
- Many TTS voices and voice models forbid redistribution — check first.

See [docs/AUDIO_GENERATION.md](docs/AUDIO_GENERATION.md).

## Before you open a PR

- Run `./smoke-test.sh` — it must pass.
- Never commit `.env`, SIP credentials, or API keys (see
  [SECURITY.md](SECURITY.md)).
- Keep diffs minimal and readable.
