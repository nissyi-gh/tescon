# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-19

### Added

- `tescon` CLI with dry-run (stdout) and `--write` / `-o` output modes
- Conversion rules: `rspec_describe`, `example_dsl`, `subject`, `expect_eq`, `is_expected_eq`
- Prism-based analyzer and byte-offset rewriter (UTF-8 safe)
- `--fixtures-hints` for FactoryBot usage → fixture YAML suggestions
- Per-rule change summary on stderr

[Unreleased]: https://github.com/nissyi-gh/tescon/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nissyi-gh/tescon/releases/tag/v0.1.0
