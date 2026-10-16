#!/bin/bash
cd -- "$(dirname -- "$0")" || exit 1
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" --script res://tools/play_art_review.gd
