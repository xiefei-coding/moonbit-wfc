# Contributing locally

This repository is independent; do not import sibling projects or share their build directories. Run `npm ci --ignore-scripts`, install Python/Pillow, and execute `./verify.ps1 -MoonPath /absolute/path/to/moon.exe` before committing. Use public-API regressions for substantive behavior, meaningful independent checks for compatibility, and avoid tests that only mirror low-impact implementation details.

`moon fmt`, `moon info` and golden generation must be idempotent. Rebuild web/engine.mjs from cmd/web after changing the core. Keep actual CLI and browser behavior, documentation, resource limits and evidence in agreement. References stay in a caller-selected external directory; routine verification uses stored official output and has no network or C# dependency.

Keep new changes local. No remote, push, publication, submission or new archive is implied by a passed test suite. Document timing scope and unsupported behavior without turning partial evidence into a parity claim.
