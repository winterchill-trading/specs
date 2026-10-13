# infra

Container images, a local compose stack, a Helm chart and deployment notes for the
organization's OxCaml services (simulators, market maker, market recorder, day close).
Not an OCaml repository.

| | |
| --- | --- |
| Repository | `winterchill-trading/infra` |
| opam package | none |
| Status | done (CI and base image green; AWS is design notes, see the roadmap) |

## Contents

| Path | Purpose |
| --- | --- |
| `images/oxcaml-base/Dockerfile` | Ubuntu 24.04, opam, `5.2.0+ox` (ox repository pinned to a commit), the org's library dependencies; linux/amd64 and linux/arm64 |
| `images/service/Dockerfile`, `build.sh REPO BIN` | Multi-stage build of one binary: pins siblings at resolved commits from the repository's own `ci.yml`, `dune build --release`, slim runtime under tini, uid 10001, optional `RUNTIME_PACKAGES`; labels the image with its commit (`org.opencontainers.image.revision`) and the sibling pins (`io.github.winterchill-trading.pins`) and tags it `:<commit12>` |
| `compose/docker-compose.yml`, `compose/recorder.sexp` | Three simulators, a market maker per venue, the recorder, MinIO and a bucket job; cAdvisor, node-exporter and Prometheus under the `monitoring` profile (loopback-only ports) |
| `compose/` profiles `copy` and `testnet`, `docs/copytrading.md`, `docs/testnet-box.md` | `copy`: hl-sim with `-leaders`, hl-leaderboard collect loop and server, hl-copy-api, hl-copy-engine (loopback), hl-copy-web on nginx with the API proxied under `/api/`; `testnet`: hl-sim anchored read-only to mainnet BTC, ETH and SOL with leaders, one hl-mm per coin and a recorder ("testnet in a box"); `make up-copy`, `make up-testnet`; Helm `copy.enabled`; not yet run end to end (Docker was down when written) |
| `charts/winterchill/` | Helm chart: recorder ConfigMap, PVC, Deployment and Service per venue, day-close CronJob per venue, S3 Secret, dev-profile simulators, optional node-exporter DaemonSet (`monitoring.enabled`); image defaults are commit tags and `latest` is rejected |
| `charts/rendered-example.yaml` | `helm template` of the dev profile, checked in CI |
| `docs/local.md`, `docs/aws.md` | Rancher Desktop setup; AWS topology, S3 layout, lifecycle, IAM, querying |
| `docs/runbook-recorder-upgrade.md`, `docs/troubleshooting.md` | Upgrading the recorder Helm release; stale streams, `ss -tipn`, uploads during DNS outages |
| `docs/runtime-tuning.md`, `scripts/gc-compare.sh` | `OCAMLRUNPARAM` comparison by peak RSS and CPU; memtrace on the ox base image |
| `test-actions/` | Chaos checks against the running stack: orders, recorder restart, network cut, upload outage |
| `Tiltfile` | Live rebuild of service images on Rancher Desktop |
| `.github/actions/ox-setup` | Composite action for every repository's CI: OxCaml switch from the `ox` repository at the base image's commit, sibling pins resolved to commits, dependencies installed, the whole switch cached (see [design/deployment.md](../design/deployment.md#ci)) |
| `docs/ci.md` | Migrating a `ci.yml` to `ox-setup`, the cache key, when it misses, timings |
| `scripts/check-pins.sh` | Derives each repository's CI pin order from the sibling `dune-project` files and fails on a missing, misordered or wrong-URL pin (`-a` checks every sibling); reads `ox-setup` `pins:` blocks and checks the `ox` commit against the base image |
| `scripts/ps.sh` | `make ps`: compose status plus each image's commit and sibling pins |
| `Makefile` | `base`, `build`, `up`, `down`, `logs`, `ps`, `lint`, `chart` |
| `.github/workflows/base-image.yml` | Builds and pushes `ghcr.io/winterchill-trading/oxcaml-base` on changes and weekly |
| `.github/workflows/service-images.yml` | Manual: pushes commit-tagged multi-arch service images to GHCR |

## Dependencies

Builds images of `hl-sim`, `binance-sim`, `bybit-sim`, `market-maker`,
`market-recorder` and `market-data` from GitHub (or local checkouts with `SRC=`).

## CI

`ci.yml`: hadolint on both Dockerfiles, shellcheck on `build.sh`, `scripts/*.sh` and
`test-actions/*.sh`, `scripts/test-check-pins.sh` on a fixture workspace, `helm lint`
(default and dev values), rendered example up to date, `docker compose config`, and the
`ox-setup-hl-sim` job running the action against an `hl-sim` checkout (a dispatch input
pins `hl-protocol` at another ref to exercise a partial cache hit).
`base-image.yml`: multi-arch build and push to GHCR. `service-images.yml`: commit-tagged
service images, run by hand.

## Measurements

`scripts/gc-compare.sh` runs one recorder per `OCAMLRUNPARAM` setting side by side
against the compose simulators (3 venues, 2 symbols each, 22 streams; Rancher Desktop,
2 vCPU, arm64), 600 s:

| Setting | Peak RSS (MB) | RSS at end (MB) | CPU (s) | Frames |
| --- | ---: | ---: | ---: | ---: |
| `o=80` | 81.8 | 65.6 | 11.7 | 85428 |
| `o=120` (default) | 87.1 | 74.3 | 11.2 | 85412 |
| `o=200` | 89.1 | 76.7 | 11.6 | 85394 |
| `o=400` | 101.3 | 84.7 | 11.7 | 85389 |

Memory follows `o`; CPU (about 2% of a core) does not, and `s=1M` changed neither in a
300 s run. The default stays; `o=80` saves about 10% RSS on a memory-bound node.
`v=0x400` prints nothing on the ox runtime. memtrace (Memprof) builds and records on the
ox base image.

Test actions on the local stack: `orders.sh hyperliquid 30` placed 198 orders with 26
maker fills; a recorder restart is healthy again within 1 s; a paused simulator is
reported stale after 29 s (30 s window) and healthy 1 s after unpause; a 240 s upload
outage left 89 files pending and the backlog drained 4 s after the restore (rclone
retries for about 150 s before failing, so alert on pending uploads, not failures).

`ox-setup` timings (`ubuntu-latest`, hl-sim, five sibling pins): a cold run with the
compiler cached takes 1046 s, a warm exact hit 91 s, a partial hit rebuilding one moved
pin 163 s. hl-sim's own CI went from about 17 minutes per push to about 2.

## Design

See [design/deployment.md](../design/deployment.md).

## Known gaps

- No infrastructure-as-code for AWS; `docs/aws.md` describes the target.
- Only `hl-sim` uses `ox-setup` so far; the other repositories still run setup-ocaml and
  `opam pin add` (rollout is wave 4).
- Compose uses a community MinIO build (`pgsty/minio`) because upstream stopped
  publishing images.
