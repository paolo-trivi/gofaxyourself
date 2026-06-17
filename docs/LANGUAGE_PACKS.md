# Language Packs

GoFaxYourself is **English-first** and **multilingual by design**.

## Policy

- English (`en`) is the reference language and ships first.
- A language "pack" is a set of **text scripts** under `scripts/<lang>/`.
- **Text scripts are committed. WAV files are generally NOT** — they are
  gitignored (`*.wav`) and generated/provided locally. The one exception is a
  file explicitly whitelisted in `.gitignore` with clear redistribution rights:
  the bundled default `audio/it/anti-call-center.wav` (project-owned). A clean
  clone therefore contains all scripts plus that one bundled default.
- No language is required except the one you actually use.

## Language codes

Lowercase ISO 639-1 two-letter codes. Initial set:

| Code | Language   |
|------|------------|
| `en` | English    |
| `it` | Italian    |
| `es` | Spanish    |
| `fr` | French     |
| `de` | German     |
| `pt` | Portuguese |

## Directory layout

```
audio/
  en/   it/   es/   fr/   de/   pt/
scripts/
  en/   it/   es/   fr/   de/   pt/
```

- `audio/<language>/` holds the WAV payloads (Tape Mode).
- `scripts/<language>/` is reserved for Script Mode snippets (see MODES.md).

## File naming convention

```
audio/<language>/<persona>.wav
```

Examples:

```
audio/en/confused-grandpa.wav
audio/it/broken-fax.wav
audio/de/angry-printer.wav
```

Persona identifiers are English-only, lowercase, hyphenated. See
[CONTRACTS.md](CONTRACTS.md) for the reserved persona list.

## Recommended WAV format

For SIP-friendly, codec-friendly audio (PCMA/PCMU / G.711):

- **Mono** (1 channel)
- **8000 Hz** sample rate
- **16-bit PCM**

Set `AUDIO_FILE_SAMPLE_RATE` to match your file (default `8000`).

Convert anything to this format with `ffmpeg`:

```bash
ffmpeg -i input.mp3 -ac 1 -ar 8000 -sample_fmt s16 audio/en/my-persona.wav
```

## How to add a language

1. Pick a language code and a persona (see CONTRACTS.md).
2. Record or convert a WAV in the recommended format.
3. Save it as `audio/<language>/<persona>.wav`.
4. Point `GOFAX_LANGUAGE` and `GOFAX_AUDIO_FILE` at it in your `.env`.
5. Open a PR. Keep it minimal — audio files only, no binaries beyond WAVs.

> Empty language directories are kept in git with `.gitkeep` placeholders so
> the structure stays stable before real audio exists.

## Script packs (text)

Before there is audio, there is a script. GoFax ships **text** script packs —
short, funny, time-wasting lines, one per line, ready to be read aloud by a
human or a text-to-speech engine later.

```
scripts/<language>/<persona>.txt
scripts/en/confused-grandpa.txt      <- canonical source
scripts/manifest.json                <- index of every script pack
```

Rules for a script file:

- Plain UTF-8 text. **No markdown** inside the file.
- At least **20 short, non-empty lines**.
- One line per idea, each usable on its own as a TTS prompt.
- Keep lines short — they become phone audio.
- English (`en`) is the canonical source. Other languages are natural
  localizations, **not** literal machine translations.
- Persona filenames stay English `kebab-case` in every language.
- Keep it public-safe: surreal bureaucracy, fake troubleshooting, fax/printer
  jokes, sysadmin exhaustion, compliance loops. No hate, threats, slurs,
  harassment, sexual content, real names, real numbers, or personal data.

### How to add a script pack

1. Copy the canonical English file for the persona you want to localize:
   `scripts/en/<persona>.txt`.
2. Rewrite the 20 lines naturally in your language (localize the jokes; don't
   translate word for word). Keep them short.
3. Save as `scripts/<language>/<persona>.txt`.
4. Add the entry to `scripts/manifest.json` (`language`, `persona`, `type`
   `text`, and `path`).
5. Run `./smoke-test.sh` to confirm structure and line counts.
6. Open a PR. Text only — no audio binaries.

### How to convert script packs to audio later

Script packs are text. Tape Mode plays **WAV** files. Converting is a separate,
manual step you (or a future Script/Brain mode) perform — GoFax does not call
any TTS API in v0.1.

A typical offline pipeline, one line per file or one file per persona:

```bash
# Example only: pick any TTS engine you have the rights to use.
# Read scripts/en/confused-grandpa.txt and synthesize speech, then normalize
# to the SIP-friendly WAV format:
ffmpeg -i raw_tts_output.any -ac 1 -ar 8000 -sample_fmt s16 \
  audio/en/confused-grandpa.wav
```

**Recommended WAV format** (same as above): **mono, 8000 Hz, 16-bit PCM**.

> ⚠️ **Redistribution rights.** Any audio you generate from these scripts —
> whether via a TTS voice, a hired voice actor, or a recording — must have
> **clear redistribution rights** before you commit or publish it. Many TTS
> voices and voice models forbid redistribution. The text scripts in this repo
> are under the project license; the **audio is your responsibility.**
