# Austral — maintenance tooling

The maintainer's working repository: it **contains no Austral code**. It is used to clone all the bundles side by side, apply the same standard files to them, configure GitHub and publish the releases.

## Requirements

`git`, `gh` (logged in: `gh auth login`), `perl`, and `php` 8.2+ / `composer`. Without a local PHP, the scripts run them through Docker (`australproject/php:8.4` and `composer:2`, to change with `AUSTRAL_PHP_IMAGE` / `AUSTRAL_COMPOSER_IMAGE`).

## Commands

| Command | Purpose |
|---------|---------|
| `bin/clone [repositories]` | Clones or updates the repositories in `bundles/` |
| `bin/status [repositories]` | Branch, local changes, latest tag, CI status |
| `bin/sync-standard [repositories]` | Applies the files from `standard/` (commits nothing) |
| `bin/setup-github [repositories] [--execute]` | `4.x` as default branch, topics, protections, vulnerability reporting |
| `bin/release <version> [--only …] [--execute]` | Checks, then tags all the repositories |

All the scripts that change GitHub are **dry runs by default**; `--execute` applies the changes.

## Conventions

- **Branches**: `4.x` = development (default branch); `3.1` = maintenance; `3.0` = frozen. A `4.0` branch is only created to maintain 4.0 while 4.1 moves forward on `4.x`.
- **Repository types** (`bundles.txt`): `bundle`, `library` (contracts) and `project` (skeleton) are versioned and follow the branches above. `tooling` repositories (`.github`, `dev`) use a single `master` branch, are not versioned, and are only handled by `bin/setup-github`.
- **Synchronized versions**: `X.Y.0` is released for **all** repositories at the same time. A fix `X.Y.Z` (Z > 0) can be released for a single repository.
- **Tags**: `vX.Y.Z`, pre-releases `vX.Y.Z-beta.N` / `vX.Y.Z-RC1`. A published tag is never moved or deleted (protected by the GitHub rules).
- **Constraints**: between bundles `"austral/xxx": "^4.0"`; `"php": ">=8.2"`; `"symfony/*": "^7.4"`. No `version` field in `composer.json`.
- **CHANGELOG**: Keep a Changelog format; the `## [X.Y.Z] - YYYY-MM-DD` section is required before tagging, and becomes the text of the GitHub Release.
- **Language**: public files (README, CHANGELOG, comments, messages) are written in English. French stays in the `*.fr.yaml` translation files.

## Releasing a version

```bash
bin/clone                      # everything is up to date
# In each repository: rename [Unreleased] to [4.1.0] - 2026-12-01, commit, push, green CI
bin/release 4.1.0              # dry run: lists all the problems, tags nothing
bin/release 4.1.0 --execute    # asks you to type v4.1.0, then tags and pushes
bin/status                     # check
```

Once the tags are pushed, the `release.yml` workflow of each repository creates the GitHub Release with the CHANGELOG section, and Packagist is updated through the GitHub hook.

Fix for a single bundle:

```bash
bin/release 4.1.1 --only form-bundle --execute
```

## Checks run by `bin/release`

For each repository, before tagging anything:

1. right branch (`X.Y` if it exists, otherwise `X.x`), clean tree, identical to `origin`;
2. tag does not exist yet, version greater than the latest tag of the same major;
3. dated section in `CHANGELOG.md`;
4. `composer.json` without a `version` field, `austral/*` constraints on `^X.Y`, `composer validate --strict`;
5. green CI on the exact commit that will be tagged.

If a single check fails on a single repository, **no tag is created**.
