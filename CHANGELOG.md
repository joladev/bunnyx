# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-08

### Added

- Pull zone management (`Bunnyx.PullZone`) — list, get, create, update, delete
- Edge storage (`Bunnyx.Storage`) — list, get, put, delete with regional endpoint support
- Cache purging (`Bunnyx.Purge`) — purge by URL or entire pull zone
- DNS zone management (`Bunnyx.DnsZone`) — list, get, create, update, delete
- DNS record management (`Bunnyx.DnsRecord`) — add, update, delete
- `Bunnyx.Error` struct for consistent error handling
- Built on Req/Finch — no custom HTTP layer
