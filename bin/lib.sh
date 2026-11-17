#!/usr/bin/env bash
# Shared functions for the Austral scripts. Not meant to be run on its own.

set -euo pipefail

ORG="${AUSTRAL_ORG:-austral-project}"
DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${AUSTRAL_WORKSPACE:-$DEV_ROOT/bundles}"
BUNDLES_FILE="$DEV_ROOT/bundles.txt"
STANDARD_DIR="$DEV_ROOT/standard"

if [ -t 1 ]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '  %s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail()  { printf '  %s✘%s %s\n' "$RED" "$RESET" "$*"; }
die()   { printf '%sError:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
title() { printf '\n%s== %s ==%s\n' "$BOLD" "$*" "$RESET"; }

require_cmd() {
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "required command not found: $c"; done
}

# php and composer through Docker when they are not installed on the machine.
# The dev folder and the workspace are mounted at the same path, so the scripts
# can pass absolute paths. Images can be changed with the variables below.
AUSTRAL_PHP_IMAGE="${AUSTRAL_PHP_IMAGE:-australproject/php:8.4}"
AUSTRAL_COMPOSER_IMAGE="${AUSTRAL_COMPOSER_IMAGE:-composer:2}"
docker_tool() { # docker_tool <image> <command> [args...]
  local image="$1" cmd="$2"; shift 2
  local mounts=(-v "$DEV_ROOT:$DEV_ROOT")
  case "$WORKSPACE/" in "$DEV_ROOT"/*) ;; *) mounts+=(-v "$WORKSPACE:$WORKSPACE") ;; esac
  docker run --rm -i -u "$(id -u):$(id -g)" -e HOME=/tmp -e COMPOSER_HOME=/tmp/composer \
    "${mounts[@]}" -w "$PWD" --entrypoint "$cmd" "$image" "$@"
}
if ! command -v php >/dev/null 2>&1 && command -v docker >/dev/null 2>&1; then
  php() { docker_tool "$AUSTRAL_PHP_IMAGE" php "$@"; }
fi
if ! command -v composer >/dev/null 2>&1 && command -v docker >/dev/null 2>&1; then
  composer() { docker_tool "$AUSTRAL_COMPOSER_IMAGE" composer "$@"; }
fi

# Lists "<repository> <type>" from bundles.txt (comments and empty lines are ignored)
all_repos() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$BUNDLES_FILE" | awk 'NF>=2 {print $1" "$2}'
}

# Repository names. "tooling" repositories (.github, dev) are only included when
# INCLUDE_TOOLING=1 (set by setup-github): the other scripts only handle versioned packages.
repo_names() {
  if [ "${INCLUDE_TOOLING:-0}" = "1" ]; then all_repos | awk '{print $1}'
  else all_repos | awk '$2!="tooling" {print $1}'; fi
}

repo_type() {
  local t
  t="$(all_repos | awk -v r="$1" '$1==r {print $2}')"
  [ -n "$t" ] || die "unknown repository in bundles.txt: $1"
  printf '%s' "$t"
}

# Same as repo_type, but refuses a "tooling" repository when the script does not handle them
check_repo() {
  local t; t="$(repo_type "$1")"
  if [ "$t" = "tooling" ] && [ "${INCLUDE_TOOLING:-0}" != "1" ]; then
    die "$1 is a tooling repository (not versioned): not handled by this script"
  fi
}

# Selection: arguments "a,b,c" or "a b c", otherwise all repositories
select_repos() {
  if [ "$#" -eq 0 ] || [ -z "${1:-}" ]; then repo_names; return; fi
  local r
  for r in $(printf '%s ' "$@" | tr ',' ' '); do check_repo "$r"; printf '%s\n' "$r"; done
}

# Call it in the main shell (not inside $(...)) so that die() really stops the script
validate_selection() {
  local r
  for r in $(printf '%s ' "$@" | tr ',' ' '); do check_repo "$r"; done
}

repo_dir() { printf '%s/%s' "$WORKSPACE" "$1"; }

# admin-bundle -> AdminBundle ; entity-file-bundle -> EntityFileBundle ; contracts -> Contracts
to_namespace() {
  printf '%s' "$1" | awk -F- '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) substr($i,2)}'
}

# admin-bundle -> admin ; entity-file-bundle -> entity_file
to_config_key() {
  printf '%s' "${1%-bundle}" | tr '-' '_'
}

# Name used in file headers: admin-bundle -> Admin Bundle ; entity-file-bundle -> EntityFile Bundle ; contracts -> Contracts
to_header_name() {
  case "$1" in
    *-bundle) printf '%s Bundle' "$(to_namespace "${1%-bundle}")" ;;
    *) to_namespace "$1" ;;
  esac
}

# admin-bundle -> Admin ; entity-file-bundle -> Entity File
to_title() {
  printf '%s' "${1%-bundle}" | awk -F- '{for(i=1;i<=NF;i++) printf "%s%s", (i>1?" ":""), toupper(substr($i,1,1)) substr($i,2)}'
}
