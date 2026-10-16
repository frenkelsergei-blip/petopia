#!/bin/bash
set -e
petopia_root="$(cd -- "$(dirname -- "$0")" && pwd)"
petopia_engine="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$petopia_engine" ]; then
  petopia_engine="$(command -v godot || command -v godot4 || true)"
fi
if [ -z "$petopia_engine" ]; then
  echo "Install Godot 4.7.2, then open project.godot."
  read -r -p "Press Return to close. " petopia_reply
  exit 1
fi
exec "$petopia_engine" --path "$petopia_root"
