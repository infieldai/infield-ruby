## [Unreleased]

## [0.8.1] - 2026-04-15

  - Guard `Warning.extend` so the gem loads on Ruby < 2.4 where the `Warning` module is not defined.

## [0.8.0] - 2025-07-17

  - Send git info alongside deprecation warnings.

## [0.7.0] - 2025-04-16

  - Send Rails.root alongside deprecation warnings so they can be hidden from callstacks

## [0.6.0] - 2025-04-10

  - Bypass Webmock in test environments.

## [0.1.0] - 2023-11-14

- Initial release
