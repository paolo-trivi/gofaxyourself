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

### Robocallers call you. This picks up. With a confused grandpa. On a loop. Forever.

A tiny SIP honeypot in one Docker container. It registers to your phone line,
**auto-answers spam calls**, and plays them a pre-recorded tape until they give
up and hang up. You do nothing. They waste their afternoon.

No PBX. No database. No web UI. No cloud. No outbound calls. Just `baresip`,
one container, and a WAV file with infinite patience.

```bash
cp .env.example .env && docker compose up -d
```

That's the whole install. The line is now live and answering.

![GoFaxYourself answering a spam call so you don't have to](demo.gif)

---

## What a call sounds like (from your logs)

```text
$ docker compose logs -f
gofax  | 39XXXXXXXXXX@sip-provider: {0/UDP/v4} 200 OK () [1 binding]   <- registered
gofax  | call: answering call on line 1 from sip:spammer@unknown with 200
gofax  | aufile: loading input file '/audio/payload.wav'
gofax  | Call established: sip:spammer@unknown
gofax  | stream: incoming rtp for 'audio' established
gofax  |   ...confused grandpa.wav plays...   "Pronto? PRONTO? Chi parla?"
gofax  | Call terminated (duration: 94 secs)                          <- 94s well spent
```

> The clip above is [`demo.cast`](demo.cast) rendered to a GIF — replay it
> yourself with `asciinema play demo.cast`.

**Want to actually hear it?** [Play the bundled tape](audio/it/anti-call-center.wav)
— click it and GitHub opens a built-in audio player. It's the real
`anti-call-center.wav` every fresh clone ships with.

---

## Why it just works and stays up

One container, supervised by Docker itself:

- `restart: unless-stopped` -> baresip is brought back automatically if it crashes.
- The Docker service starts at boot -> the line comes back after a host reboot.
- No terminal to keep open, no background script to babysit.

```bash
docker compose ps          # status + health
docker compose logs -f     # live call activity
docker compose restart     # reload after editing .env or the WAV
docker compose down        # stop (and stay stopped)
```

**One rule:** run exactly one registrant per phone account. Don't start a second
copy against the same line, or two clients fight over the registration and it
stops answering.

---

## The persona pack

Pick who answers your spammers. Scripts live in [`personas/`](personas/) —
ready-to-read, meme-grade, safe (no real targets, no threats, just absurdity).

| Persona | Energy |
|---|---|
| [confused-grandpa](personas/confused-grandpa.txt) | "Pronto? Is this about the warranty? My grandson handles the warranty." |
| [broken-fax](personas/broken-fax.txt) | Eternal handshake. Please resend page 1 of 1. BEEEEEEP. |
| [angry-printer](personas/angry-printer.txt) | PC LOAD LETTER. There is no tray 4. There has never been a tray 4. |
| [compliance-loop](personas/compliance-loop.txt) | To verify your identity, please first verify your identity. |

The bundled default (`audio/it/anti-call-center.wav`) works out of the box.
To make a persona talk, turn its script into a WAV and point `.env` at it:

```bash
# any text -> SIP-ready WAV (needs espeak + ffmpeg)
espeak -v en -s 150 -f personas/confused-grandpa.txt --stdout \
  | ffmpeg -i - -ar 8000 -ac 1 -acodec pcm_s16le audio/en/confused-grandpa.wav

# then in .env:
#   GOFAX_AUDIO_FILE=./audio/en/confused-grandpa.wav
docker compose restart
```

Robotic TTS voice? Even better. That's the whole bit.

---

## Configuration

Everything lives in `.env` (gitignored — it holds your SIP password):

| Key | What |
|---|---|
| `SIP_USERNAME` / `SIP_PASSWORD` | your SIP account |
| `SIP_DOMAIN` | the `@domain` of your SIP address (e.g. `windtre.it`) |
| `SIP_SERVER` | registrar / proxy host (often the same) |
| `GOFAX_AUDIO_FILE` | the WAV played to callers (mono, 8000 Hz, 16-bit PCM) |
| `DNS_SERVER` | optional; empty = system DNS |
| `GOFAX_LOG_ENABLED` | optional CDR/SIP logs to `./logs` (real numbers — gitignored) |

---

## Boring but important

GoFaxYourself is **inbound-only and defensive**. It answers calls placed *to
you*. It does not place calls, autodial, enumerate numbers, or automate
harassment, and it never will. The joke is wasting a robocaller's time, not
hurting anyone. Keep it that way. See [LICENSE](LICENSE).
