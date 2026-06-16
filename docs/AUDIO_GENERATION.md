# Audio Generation & Provenance

GoFaxYourself ships **text scripts**, not voices. Audio is an **optional,
developer-side build step**. The runtime (`./gofax` + baresip + Docker) never
generates audio and never calls a TTS service.

> **When in doubt, commit the script, not the voice.**

## Why provenance matters

A WAV is a binary blob. Once it is in a public repo, you are redistributing it.
Many TTS engines, system voices, and voice models **forbid redistribution** of
their output. So every audio file in this repo must carry recorded provenance
and a clear redistribution status in [`../audio/manifest.json`](../audio/manifest.json).

The MIT [LICENSE](../LICENSE) covers code and text scripts — **not** audio.

## Recommended WAV format (SIP-friendly)

- Container: **WAV**
- Channels: **mono** (1)
- Sample rate: **8000 Hz**
- Sample format: **16-bit PCM** (`s16` / `pcm_s16le`)

## audio/manifest.json contract

Every generated/recorded WAV must have an entry in `audio/manifest.json` with
these fields:

| Field           | Meaning                                                     |
|-----------------|-------------------------------------------------------------|
| `language`      | Language code (`en`, `it`, ...)                             |
| `persona`       | Persona id (`confused-grandpa`, ...)                       |
| `source_script` | Path to the source text, e.g. `scripts/en/confused-grandpa.txt` |
| `provider`      | What produced the audio (`espeak`, `voice-actor`, `placeholder-tone`, ...) |
| `generated_at`  | Date the audio was produced (`YYYY-MM-DD`)                  |
| `output`        | Output WAV path, e.g. `audio/en/confused-grandpa.wav`      |
| `sample_rate`   | e.g. `8000`                                                 |
| `channels`      | e.g. `1`                                                    |
| `sample_format` | e.g. `s16`                                                  |
| `redistribution`| `public-domain`, `cc0`, `owner-permitted`, `unknown`, ...  |
| `notes`         | Free text: licensing, voice, caveats                       |

If `redistribution` is `unknown`, **do not publish the file.**

## Optional local TTS toolchain (espeak)

Tools live in [`../tools/`](../tools/) and are **not** runtime dependencies.
They are not installed by the Dockerfile and not called by `./gofax`.

Requirements (install yourself, dev-side only):

- [`espeak`](https://espeak.sourceforge.net/) or `espeak-ng` — offline TTS
- [`ffmpeg`](https://ffmpeg.org/) — audio normalization

Both tools fail with a clear message if a requirement is missing.

### Generate audio for one persona

```bash
tools/generate-audio.sh <language> <persona> [espeak-voice]

# Example:
tools/generate-audio.sh en confused-grandpa
```

This reads `scripts/<language>/<persona>.txt`, synthesizes speech with espeak,
normalizes to mono/8000 Hz/16-bit PCM, and writes
`audio/<language>/<persona>.wav`. It then prints a ready-to-paste
`audio/manifest.json` provenance entry (espeak output is generally
redistributable, but confirm for your espeak build/voice).

### Normalize an existing audio file

```bash
tools/normalize-audio.sh <input-audio> <output.wav>
```

Forces any input to the SIP-friendly WAV format above.

## The bundled placeholder

`audio/en/confused-grandpa.wav` is a **silent-ish placeholder**: a short
1000 Hz tone followed by silence, generated locally in pure shell (a WAV header
plus square-wave and zero PCM samples). It is **not speech**, it is public
domain, and it exists only so the default config works out of the box.

Replace it with real audio when you are ready:

```bash
tools/generate-audio.sh en confused-grandpa
```

The previous example recording was removed because its provenance was unclear
and it could not be treated as cleanly redistributable.
