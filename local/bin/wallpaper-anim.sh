#!/usr/bin/env bash
WALLDIR="$HOME/Изображения/Wallpapers"
DEFAULT="$WALLDIR/Samurai-Autumn-1080p60.mp4"
killall mpvpaper 2>/dev/null
sleep 1
VIDEO="${1:-$DEFAULT}"
if [ ! -f "$VIDEO" ]; then
    echo "not found: $VIDEO" >&2
    exit 1
fi
FRAME="${VIDEO%.*}.png"
if command -v ffmpeg >/dev/null 2>&1 && [ ! -f "$FRAME" ]; then
    ffmpeg -v error -ss 5 -i "$VIDEO" -frames:v 1 -q:v 2 "$FRAME" -y
fi
if command -v noctalia >/dev/null 2>&1 && [ -f "$FRAME" ]; then
    noctalia msg wallpaper-set "$FRAME" >/dev/null 2>&1
fi
mpvpaper -f -l background -o "no-audio loop-file=inf hwdec=auto-safe keep-open=yes" "*" "$VIDEO" 2>/dev/null &
