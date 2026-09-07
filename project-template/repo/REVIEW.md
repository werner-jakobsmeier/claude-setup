# Review policy — {{TITLE}}

## The documentation trigger
**Does this change alter behaviour described in `docs/`? Then `docs/` changes in this PR.**
This is the single rule that keeps documentation from rotting. Structure alone decays; the trigger is what holds.

## Passes
1. **Correctness** — does it do what the spec says, including edge cases and failure paths.
2. **Security** — authorization checked server-side; no secret reachable from the client bundle; untrusted input validated.
3. **Docs** — the trigger above.
4. **Simplification** — reuse before adding; delete before abstracting.

## Severity
- **Blocking** — wrong behaviour, security, data loss, or undocumented behaviour change.
- **Should fix** — clarity, duplication, missing test on a real risk.
- **Optional** — taste.
