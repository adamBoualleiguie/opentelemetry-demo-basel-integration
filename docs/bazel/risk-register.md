# Bazel migration risk register (M0)

Review before **M2** (first language wave) and update each milestone.

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
|----|------|--------|------------|------------|-------|
| R1 | Rule maturity differs by language (Ruby/PHP/Elixir/.NET) | Schedule slip | Med | Wrapper rules first; native rules later; explicit waivers in tracker | _TBD_ |
| R2 | Dual pipeline (Make + Bazel) maintenance | Confusion, drift | High | Time-box M0–M1; deprecate duplicate gates per milestone | _TBD_ |
| R3 | Remote cache misconfiguration / poisoning | Bad artifacts | Low | Auth’d cache, read-only for PRs, lock down writes | _TBD_ |
| R4 | Flaky trace/Cypress tests under CI | Red builds | Med | Tags, quarantine, retries policy; split infra vs app failures | _TBD_ |
| R5 | Contributor onboarding friction | Fewer PRs | Med | Docs (`docs/bazel/milestones/`, `4-bazel-dev-environment-ubuntu.md`), thin Make wrappers | _TBD_ |
| R6 | Non-hermetic `bazel run //:lint` (host tools) | Local vs CI skew | Med | Document prerequisites; replace with true Bazel actions in later milestones | _TBD_ |
