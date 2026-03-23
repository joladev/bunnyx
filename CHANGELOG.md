# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-23

### Added

**CDN & Caching**
- Pull zone management (`Bunnyx.PullZone`) — CRUD, hostnames, SSL/certificates, edge rules, referrers, IP blocking, statistics
- Cache purging (`Bunnyx.Purge`) — purge by URL or entire pull zone

**DNS**
- DNS zone management (`Bunnyx.DnsZone`) — CRUD, DNSSEC, zone export/import, statistics, availability check, certificate issuance
- DNS record management (`Bunnyx.DnsRecord`) — add, update, delete

**Storage**
- Storage zone management (`Bunnyx.StorageZone`) — CRUD, statistics, password reset, availability check
- Edge storage (`Bunnyx.Storage`) — upload, download, delete, list files
- S3-compatible storage (`Bunnyx.S3`) — PUT, GET, DELETE, HEAD, COPY, ListObjectsV2, full multipart upload support

**Video**
- Video library management (`Bunnyx.VideoLibrary`) — CRUD, API key rotation, watermarks, referrers, transcribing/DRM statistics
- Video streaming (`Bunnyx.Stream`) — video CRUD, upload, fetch, collections, captions, thumbnails, re-encode, repackage, transcription, smart actions, analytics, oEmbed

**Security**
- Shield (`Bunnyx.Shield`) — zone management, WAF rules (built-in + custom), rate limiting, access lists, bot detection, upload scanning, API Guardian, metrics, event logs

**Compute**
- Edge scripting (`Bunnyx.EdgeScript`) — script CRUD, code management, releases, secrets, variables
- Magic containers (`Bunnyx.MagicContainers`) — app lifecycle, registries, container templates, endpoints, autoscaling, regions, volumes, pods, log forwarding

**Account & Billing**
- Billing (`Bunnyx.Billing`) — details, summary, pending payments, PDF downloads
- Account (`Bunnyx.Account`) — affiliate info, audit log, search, close account
- API key listing (`Bunnyx.ApiKey`)
- CDN and origin error logging (`Bunnyx.Logging`)

**Reference Data**
- Global statistics (`Bunnyx.Statistics`)
- Countries (`Bunnyx.Country`) and regions (`Bunnyx.Region`)

**Core**
- `Bunnyx.Error` struct with status, message, method, path fields
- `Bunnyx.HTTP` — single HTTP entry point with telemetry events (start/stop/exception)
- `Bunnyx.Params` — key mapping with validation (unknown keys raise `ArgumentError`)
- Per-request `:receive_timeout` and pass-through `:req_opts`
- Credential protection — `Inspect` derivation excludes secrets on all client and response structs
- Error message sanitization — API keys scrubbed from error output
