# Security Policy

## Supported versions

yantra is pre-1.0. Security fixes land on the latest released minor only.

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅ |
| < 0.1.0 | ❌ |

## Reporting a vulnerability

**Do not open a public issue for security reports.**

Email **robert.maccracken@gmail.com** with:

- a description of the vulnerability and its impact,
- steps to reproduce (a minimal `.tcyr` or transcript is ideal),
- the yantra version (`VERSION`) and Cyrius pin (`cyrius.cyml`).

You'll get an acknowledgement within 72 hours. Coordinated disclosure: we'll
agree a timeline before any public detail, and credit reporters who want it.

## Scope and hardening posture

yantra drives external processes (browsers, emulators, WebDriver/Appium
endpoints) and parses untrusted protocol responses, so the relevant classes:

- **No shell-out** — process spawning uses `execve` with explicit argv, never
  a shell string.
- **Control-byte sanitization** on anything echoed to stderr (ANSI-injection
  defense).
- **Transport endpoints** authenticate via sigil-verified HTTPS certs
  (lands with the M8 hardening pass — see the roadmap).
- **Session IDs are opaque** to consumers; internal state never leaks into
  error messages.

Audit findings are filed under `docs/audit/YYYY-MM-DD-audit.md`.
