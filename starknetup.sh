#!/bin/sh
# shellcheck shell=dash

set -eu

ASDF_REPO="https://github.com/asdf-vm/asdf"
SCARB_UNINSTALL_DOCS="https://docs.swmansion.com/scarb/download#uninstall"
STARKNET_FOUNDRY_UNINSTALL_DOCS="PENDING"
SCRIPT_VERSION="0.1.0"

usage() {
    cat <<EOF
The installer for starknetup

Usage: $0 [OPTIONS]

Options:
  -h, --help      Print help
  -V, --version   Print script version

EOF
}

main() {
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage
                exit 0
                ;;
            -V|--version)
                printf "starknetup %s\n" "$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                err "invalid option '$arg'. For more information, try '--help'."
                exit 1
                ;;
        esac
    done

    assert_dependencies
    assert_not_installed "scarb" $SCARB_UNINSTALL_DOCS
    install_latest_asdf_plugin "scarb"
    install_latest_version "scarb"
    set_global_version "scarb"

    assert_not_installed "starknet-foundry" $STARKNET_FOUNDRY_UNINSTALL_DOCS
    install_latest_asdf_plugin "starknet-foundry"
    uninstall_latest_version "starknet-foundry"
    install_latest_version "starknet-foundry"
    set_global_version "starknet-foundry"

    say "Installation complete"
}

assert_dependencies() {
    need_cmd curl
    need_cmd git
    if ! check_cmd asdf; then
        err "asdf-vm is required. Please refer to ${ASDF_REPO} for installation instructions."
    fi
}

assert_not_installed() {
    local tool="$1"
    local uninstall_docs_url="$2"

    if ! asdf which "$tool" > /dev/null 2>&1; then
        if check_cmd "$tool"; then
            err "$tool is already installed outside of asdf. Please uninstall it and re-run this script. Refer to $uninstall_docs_url"
        fi
    fi
}

install_latest_asdf_plugin() {
    local plugin="$1"
    if asdf plugin list | grep -q "$plugin"; then
        ensure asdf plugin update "$plugin"
    else
        ensure asdf plugin add "$plugin"
    fi
}

install_latest_version() {
    local tool="$1"
    ensure asdf install "$tool" latest
}

uninstall_latest_version() {
    local tool="$1"
    local latest_version
    latest_version=$(asdf latest "$tool")
    
    if asdf list "$tool" "^${latest_version}$" >/dev/null 2>&1; then
        ensure asdf uninstall "$tool" "$latest_version"
    fi
}

set_global_version() {
    local tool="$1"
    ensure asdf global "$tool" latest
}

say() {
    printf "starknetup: %s\n" "$1"
}

err() {
    say "$1" >&2
    exit 1
}

need_cmd() {
    if ! check_cmd "$1"; then
        err "need '$1' (command not found)"
    fi
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}

main "$@" || exit 1
