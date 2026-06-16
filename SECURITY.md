# Security Policy

GoFaxYourself is tiny, offline-by-default, and has no web UI. The biggest risk
is not a code exploit — it is **committing secrets**.

## Never commit secrets

- **Never commit `.env`.** It is gitignored. Keep it that way.
- **Never commit SIP credentials** (`SIP_USERNAME`, `SIP_PASSWORD`, `SIP_DOMAIN`,
  `SIP_SERVER`). Use `.env.example` with empty values as the template.
- **Never commit API keys.** Brain Mode placeholders (`GOFAX_LLM_API_KEY`,
  `GOFAX_TTS_*`) must stay empty in the repo. They are reserved and unused.
- Do not paste real numbers, real credentials, or capture/log files containing
  them into issues, PRs, or commit messages.

If you accidentally commit a secret: rotate it immediately with your SIP
provider, then scrub history. A leaked key is a compromised key.

## Scope

This project only answers inbound SIP calls and plays a local WAV. It places no
outbound calls and contacts no cloud service by default. See
[docs/SAFETY.md](docs/SAFETY.md) for acceptable-use boundaries.

## Reporting a vulnerability

Responsible disclosure is appreciated.

- Open a GitHub issue for non-sensitive reports.
- For anything sensitive (a secret-handling flaw, for example), report it
  privately instead of filing a public issue: open a **GitHub Security
  Advisory** on the repo, or contact the maintainer
  **[@paolo-trivi](https://github.com/paolo-trivi)**.

Please give a reasonable chance to respond before public disclosure.
