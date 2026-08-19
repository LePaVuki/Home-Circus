# Home-Circus Development TODO

## Current decisions

- **Release policy:** Every successful merge/push to `main` automatically creates the next stable SemVer release.
- **Version baseline:** Existing repository tags are authoritative. Do not reset or invent a new version baseline.
- **Ollama:** Keep host port `11434` exposed for LAN/cross-project integration (C2). WAN access must remain blocked by firewall/network policy.
- **Root domain:** `ROOT_DOMAIN` redirects to `chat.ROOT_DOMAIN` (D1). `chat.ROOT_DOMAIN` remains behind Authelia.
- **Configuration/secrets:** Use one global untracked `.env` for configuration and credentials. Keep generated Authelia cryptographic secrets as separate files.
- **Monitoring:** Low priority for now.
- **Dockerfiles:** Keep the currently thin Dockerfiles for future customization; remove only if they remain unnecessary after the architecture stabilizes.

---

## P0 — Security / secrets

**GitHub issue:** #12 — Harden global `.env` and secret handling

- [x] Fix `scripts/utils/env.sh` to read `$ENV_FILE`, not a hard-coded `.env`.
- [x] Never log environment variable values; debug output may only identify names/counts.
- [x] Validate required variables before deployment.
- [x] Audit scripts for accidental secret output and tracing (`set -x`).
- [x] Keep `.env` ignored and `.env.example` free of real credentials.
- [x] Keep generated Authelia secrets as `600` file-based secrets.
- [x] Rotate/revoke the old Open Terminal API key if it was a real credential.
- [ ] Add secret scanning to CI.

## P1 — SemVer / release automation

**GitHub issue:** #14 — Redesign SemVer release workflow

- [ ] Inspect existing tags and establish the actual GitVersion baseline.
- [ ] Keep Conventional Commit bump semantics: `feat` = minor, fixes/maintenance = patch, breaking changes = major.
- [ ] PR workflows must never create or push tags.
- [ ] Only successful `main` releases may create stable tags.
- [ ] Make tagging/release creation idempotent.
- [ ] Verify major/minor/patch/no-bump cases against real repository history.
- [ ] Decide/document handling of `release/*` branches without allowing accidental stable releases.
- [ ] Create GitHub Releases after stable tags if appropriate.

## P1 — CI

**GitHub issue:** #13 — Build comprehensive pull request validation workflow

- [ ] ShellCheck all shell scripts.
- [ ] Validate Docker Compose configuration.
- [ ] Validate YAML/configuration files.
- [ ] Lint Dockerfiles.
- [ ] Run secret scanning.
- [ ] Run practical vulnerability scanning.
- [ ] Verify required project files.
- [ ] Calculate GitVersion for visibility without tagging.
- [ ] Keep PR permissions read-only.

## P1 — Resource limits

**GitHub issue:** #15 — Add Docker Compose resource limits

- [ ] Add modest CPU/memory limits for Caddy and Authelia.
- [ ] Add moderate limits for Open WebUI.
- [ ] Constrain Open Terminal.
- [ ] Leave Ollama flexible initially; retain GPU reservation.
- [ ] Keep limits declared in Compose; menu integration can come later.

## P1 — Network/security topology

**GitHub issues:** #16, #17

- [ ] Document frontend/backend network intent.
- [ ] Document Ollama's intentional LAN host-port exception.
- [x] Confirm firewall blocks WAN access to `11434`.
- [x] Decide whether binding `11434` to a specific LAN address is preferable to all interfaces.
- [x] Implement `ROOT_DOMAIN` → `chat.ROOT_DOMAIN` redirect.
- [x] Preserve URI paths through the redirect.
- [x] Verify no redirect/authentication loop and retest existing issue #6.

## P2 — Image/version management

- [ ] Learn/check current image versions before pinning.
- [ ] Decide whether to pin tags only or tags + digests.
- [ ] Document image update procedure.
- [ ] Consider automated image update detection later.

## P2 — Script system stabilization

- [ ] Run ShellCheck across all scripts.
- [ ] Test clean installation.
- [ ] Test already-initialized installation.
- [ ] Test missing/malformed `.env`.
- [ ] Test missing Docker / unavailable Docker daemon.
- [ ] Test service startup failures.
- [ ] Verify useful exit codes and idempotency.
- [ ] Verify secrets never appear in output.

## P3 — Monitoring

- [ ] Prometheus
- [ ] Grafana
- [ ] Container metrics
- [ ] GPU metrics
- [ ] Ollama metrics
- [ ] Caddy metrics
- [ ] Authelia/authentication events

## P3 — Documentation

- [ ] Architecture diagram
- [ ] Installation/configuration guide
- [ ] Security model
- [ ] Network topology
- [ ] Backup/restore
- [ ] Upgrade procedure
- [ ] Release procedure
- [ ] Troubleshooting

---

## Recommended implementation order

1. Secrets/env handling (#12)
2. SemVer/release automation (#14)
3. PR CI (#13)
4. Root-domain redirect + network hardening (#17, #16)
5. Resource limits (#15)
6. Script-system validation
7. Image pinning
8. Monitoring
9. Documentation polish
