# Logging — anti-call-center CDRs

GoFax can turn the spam calls it answers into a structured, queryable log: one
NDJSON record per inbound call. It stays true to the project: **pure Bash, no
PBX, no database, no dashboard, no background service, no cloud.** baresip is
already the SIP engine and already supports a SIP trace (`-s`); this feature
just persists what would otherwise scroll past on stdout.

It is **off by default** and **inbound-only / passive** — it observes calls,
it never places them.

## Enable it

In `.env`:

```bash
GOFAX_LOG_ENABLED=true
GOFAX_LOG_HASH_PEPPER=<a long random secret>   # for the caller-id hash
GOFAX_LOG_REDACT=false                          # true = drop clear-text number
```

Then run as usual:

```bash
./gofax
```

GoFax creates a local `logs/` directory (mounted into the container at `/logs`)
and writes, per UTC day:

```
logs/cdr-YYYY-MM-DD.ndjson          # one JSON object per line, per call
logs/baresip-raw-<timestamp>.log    # verbatim baresip output (raw artifact)
```

> `logs/` is **gitignored** (`logs/`, `*.ndjson`). It contains real caller
> numbers — treat it like `.env` and never commit it.

## What a record looks like

```json
{
  "session_id": "f1c2…",
  "ts_start": "2026-06-19T10:00:00Z",
  "ts_answer": "2026-06-19T10:00:01Z",
  "ts_end": "2026-06-19T10:01:30Z",
  "duration_s": 89,
  "direction": "inbound",
  "caller": { "raw": "+39055123456", "hash": "sha256:ab12…", "display": "SPAM CALLER" },
  "callee": "sip:you@sip.example.net",
  "final_status": { "code": 200, "reason": "OK" },
  "sip": { "user_agent": "SomeUA/1.0", "call_id": "…" },
  "node": { "container_id": "host", "host_network": true, "trace_enabled": true },
  "audio": { "playback_file": "payload.wav", "sample_rate": 8000 },
  "raw_ref": "baresip-raw-20260619T100000Z.log"
}
```

Fields GoFax cannot extract from baresip's output are emitted as `null` rather
than guessed. This is a deliberately small, honest subset of the much larger
schema in [logging_and_audit_voip.md](../logging_and_audit_voip.md).

## Privacy: hash and/or clear text

The caller id is stored **two ways**:

- `caller.hash` — `sha256(GOFAX_LOG_HASH_PEPPER + caller)`. Lets you count and
  correlate repeat callers without storing the number itself. The pepper makes
  the hash hard to brute-force back to a phone number, so **set a real one**.
- `caller.raw` — the clear-text number, for immediate readability. Set
  `GOFAX_LOG_REDACT=true` to drop this field and keep only the hash.

The SIP password is never logged. The raw artifact log is the unparsed baresip
output, kept so nothing is lost if parsing misses a line — it is just as
sensitive as the CDR and lives under the same gitignored `logs/`.

## Querying with jq

No database needed — `jq` over NDJSON covers the common questions:

```bash
# Pretty-print today's calls
jq . logs/cdr-$(date -u +%F).ndjson

# Count calls per distinct caller (by hash — works even when redacted)
jq -r '.caller.hash' logs/*.ndjson | sort | uniq -c | sort -rn

# Top clear-text callers
jq -r '.caller.raw // "redacted"' logs/*.ndjson | sort | uniq -c | sort -rn

# Total time wasted (seconds) across all logged calls
jq -s 'map(.duration_s // 0) | add' logs/*.ndjson

# Calls that actually connected (answered) longer than 30s
jq 'select(.ts_answer != null and (.duration_s // 0) > 30)' logs/*.ndjson
```

## Out of scope (on purpose)

[logging_and_audit_voip.md](../logging_and_audit_voip.md) describes a full
telecom-observability stack. GoFax deliberately does **not** ship: HEP/Homer
collectors, ClickHouse / Elasticsearch / Parquet, web dashboards, an
always-on pcap/tshark sidecar, the Python `tshark → CDR` analyzer, or
multi-point fraud scoring. Those belong to an edge/SBC deployment, not a tiny
standalone honeypot. If GoFax ever grows beyond that, the NDJSON CDR here is a
clean feed to forward upstream — but that is a future, not a default.
