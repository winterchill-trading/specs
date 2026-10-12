# infra

Container images, a local compose stack, a Helm chart and deployment notes for the
organization's OxCaml services (simulators, market maker, market recorder, day close).
Not an OCaml repository.

| | |
| --- | --- |
| Repository | `winterchill-trading/infra` |
| opam package | none |
| Status | in progress (base image workflow running; AWS is design notes) |

## Contents

| Path | Purpose |
| --- | --- |
| `images/oxcaml-base/Dockerfile` | Ubuntu 24.04, opam, `5.2.0+ox` (ox repository pinned to a commit), the org's library dependencies; linux/amd64 and linux/arm64 |
| `images/service/Dockerfile`, `build.sh REPO BIN` | Multi-stage build of one binary: pins siblings from the repository's own `ci.yml`, `dune build --release`, slim runtime, uid 10001, optional `RUNTIME_PACKAGES` |
| `compose/docker-compose.yml`, `compose/recorder.sexp` | Three simulators, a market maker per venue, the recorder, MinIO and a bucket job |
| `charts/winterchill/` | Helm chart: recorder ConfigMap, PVC, Deployment and Service per venue, day-close CronJob per venue, S3 Secret, dev-profile simulators |
| `charts/rendered-example.yaml` | `helm template` of the dev profile, checked in CI |
| `docs/local.md`, `docs/aws.md` | Rancher Desktop setup; AWS topology, S3 layout, lifecycle, IAM, querying |
| `Tiltfile` | Live rebuild of service images on Rancher Desktop |
| `Makefile` | `base`, `build`, `up`, `down`, `logs`, `ps`, `lint`, `chart` |
| `.github/workflows/base-image.yml` | Builds and pushes `ghcr.io/winterchill-trading/oxcaml-base` on changes and weekly |

## Dependencies

Builds images of `hl-sim`, `binance-sim`, `bybit-sim`, `market-maker`,
`market-recorder` and `market-data` from GitHub (or local checkouts with `SRC=`).

## CI

`ci.yml`: hadolint on both Dockerfiles, shellcheck on `build.sh`, `helm lint` (default
and dev values), rendered example up to date, `docker compose config`.
`base-image.yml`: multi-arch build and push to GHCR.

## Design

See [design/deployment.md](../design/deployment.md).

## Known gaps

- No infrastructure-as-code for AWS; `docs/aws.md` describes the target.
- The service image replays the repository's CI pin lines, so `market-maker` images fail
  to build until its CI pins `parquet` and `market-data`.
- Compose uses a community MinIO build (`pgsty/minio`) because upstream stopped
  publishing images.
