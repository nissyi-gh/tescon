# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `--annotate` inserts `# tescon:` review/todo comments (idempotent per rule)
- Notice detectors for `before(:all)` / `after(:all)` and `before(:context)` / `after(:context)`
- `expect_include`, `expect_match`, and `expect_raise_error` conversion rules
- `let_bang` rule: `let!(:name)` → `let(:name)` + `before { name }`
- `expect_be_present` rule: `be_present` / `be_blank` / `be_empty` → `must_be` predicates
- `expect_be_valid` rule: `be_valid` / `be_invalid` → `must_be :valid?` / `:invalid?`
- `expect_be_kind_of` rule: `be_a` / `be_an` / `be_kind_of` → `must_be_instance_of` / `must_be_kind_of`
- `--mark-source` inserts an idempotent `# tescon: converted from PATH` header comment
- `expect_be_nil` rule: `expect(x).to be_nil` → `expect(x).must_be_nil`
- `expect_be_truthy` rule: `expect(x).to be_truthy` / `be_falsey` → `must_equal` / `wont_equal`
- `before_each` rule: `before(:each)` / `after(:each)` → `before` / `after`

## [0.1.0] - 2026-05-19

### Added

- `tescon` CLI with dry-run (stdout) and `--write` / `-o` output modes
- Conversion rules: `rspec_describe`, `example_dsl`, `subject`, `expect_eq`, `is_expected_eq`
- Prism-based analyzer and byte-offset rewriter (UTF-8 safe)
- `--fixtures-hints` for FactoryBot usage → fixture YAML suggestions
- Per-rule change summary on stderr

[Unreleased]: https://github.com/nissyi-gh/tescon/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nissyi-gh/tescon/releases/tag/v0.1.0
