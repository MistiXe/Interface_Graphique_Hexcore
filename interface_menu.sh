#!/bin/sh
printf '\033c\033]0;%s\a' interface_menu
base_path="$(dirname "$(realpath "$0")")"
"$base_path/interface_menu.arm64" "$@"
