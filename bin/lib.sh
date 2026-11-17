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

# Lists "<repository> <type>" from bundles.txt (comments and empty lines are ignored)
all_repos() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$BUNDLES_FILE" | awk 'NF>=2 {print $1" "$2}'
}

repo_names() { all_repos | awk '{print $1}'; }

repo_type() {
  local t
  t="$(all_repos | awk -v r="$1" '$1==r {print $2}')"
  [ -n "$t" ] || die "unknown repository in bundles.txt: $1"
  printf '%s' "$t"
}

# Selection: arguments "a,b,c" or "a b c", otherwise all repositories
select_repos() {
  if [ "$#" -eq 0 ] || [ -z "${1:-}" ]; then repo_names; return; fi
  local r
  for r in $(printf '%s ' "$@" | tr ',' ' '); do repo_type "$r" >/dev/null; printf '%s\n' "$r"; done
}

# Call it in the main shell (not inside $(...)) so that die() really stops the script
validate_selection() {
  local r
  for r in $(printf '%s ' "$@" | tr ',' ' '); do repo_type "$r" >/dev/null; done
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
