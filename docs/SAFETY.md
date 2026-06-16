# Safety & Acceptable Use

GoFaxYourself is a **defensive** tool. Read this before you run it.

## What this project does

- It **only answers inbound calls**.
- It registers to your SIP account and auto-answers whoever calls *you*.
- It plays a pre-recorded WAV file at the caller.

That's it. It is a honeypot / answering machine for spam calls.

## What this project must NOT do

- **No outbound calls.** GoFax never originates a call.
- **No autodialing.** It does not dial numbers, lists, or ranges.
- **No harassment automation.** It is not a tool for bothering people.
- **No war-dialing, no robocalling, no bulk anything.**

These are non-goals by design (see [CONTRACTS.md](CONTRACTS.md)). The runtime
has no code path that places a call.

## Intended purpose

Defensive spam-call handling. Let the spammers talk to a tape of a confused
grandpa instead of wasting your time. Waste *theirs* instead, passively, on
calls they chose to make to you.

## Your responsibilities

- You are responsible for complying with **all local laws** on call recording,
  call handling, and telephony in your jurisdiction.
- You are responsible for complying with your **SIP/telecom provider's terms
  of service**.
- Recording or playing audio to callers may be regulated where you live. Know
  the rules before you point this at a live line.

If you cannot use this lawfully where you are, **don't use it**.
