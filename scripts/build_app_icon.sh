#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
swift ./scripts/build_app_icon.swift
