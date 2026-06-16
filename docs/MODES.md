# Modes

GoFaxYourself has three modes. Exactly one is real today.

## Tape Mode (`tape`) — default, implemented

Old-skool mode. Plays pre-recorded WAV files at the caller.

- **Status:** implemented and default.
- **Requires:** nothing but a SIP account and a WAV file.
- **No API keys.** No network dependency beyond SIP registration.
- **Fully offline** apart from talking to your own SIP provider.

This is the mode you want. It is boring, predictable, and it works.

```
GOFAX_MODE=tape
GOFAX_AUDIO_FILE=./audio/en/confused-grandpa.wav
```

## Script Mode (`script`) — reserved

Reserved for locally chosen, randomized audio snippets / simple scripted
sequences (e.g. pick a random WAV per call, chain a few clips). Stays fully
offline and WAV-based.

- **Status:** reserved. Contract only. Not implemented in v0.1.
- **Intent:** local randomization, no network, no LLM, no API keys.
- The runner will refuse to start with `GOFAX_MODE=script` until this lands.

The `scripts/<language>/` directories exist to host these snippets later.

## Brain Mode (`brain`) — reserved, disabled by default

Reserved for *optional* LLM + TTS chaos. Burn tokens for justice, generate
nonsense on the fly, synthesize a voice. This is the fun, expensive, optional
future — **not** the point of the project.

- **Status:** reserved. Contract only. **Disabled by default.**
- **No LLM provider is called in v0.1.** The code does not integrate any API.
- Requires explicit opt-in via env vars, all of which default to off:

```
GOFAX_LLM_ENABLED=false      # must be false in v0.1
GOFAX_LLM_PROVIDER=
GOFAX_LLM_MODEL=
GOFAX_LLM_API_KEY=

GOFAX_TTS_ENABLED=false      # must be false in v0.1
GOFAX_TTS_PROVIDER=
GOFAX_TTS_VOICE=
```

If you set `GOFAX_LLM_ENABLED=true` or `GOFAX_TTS_ENABLED=true` in v0.1, the
runner stops and tells you Brain Mode is not wired up yet. That is by design.

The default mode must always remain fully offline and WAV-based.
