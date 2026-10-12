# ADR 0005: Command-based uploader

Status: accepted

## Context

Closed raw files must reach an object store: S3 in production, MinIO locally, possibly
GCS or R2 later. An OCaml S3 client means request signing (SigV4), multipart uploads,
credential chains (instance roles, environment, files) and retries, per store.

## Decision

The recorder's `Uploader` runs a configured external command per closed file, with
`{file}` and `{rel}` substituted, retried with backoff, at most 4 at once, with a
persistent pending list. Deployments use `rclone copyto`, configured from the
environment.

## Consequences

- One code path covers every store rclone supports; credentials follow rclone's
  conventions (instance role through `env_auth` on EC2).
- Tests use a fake command (`cp`), with no network.
- One process per file: fine at tens of files per minute, wasteful at thousands.
- Upload metrics are limited to counts of uploads, failures and pending files.
- Revisit when the conditions in
  [design/cloud-sinks-and-replication.md](../design/cloud-sinks-and-replication.md)
  hold.
