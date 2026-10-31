#!/bin/sh
# Rename a finished gpu-screen-recorder clip to a numbered, human-readable name.
# gpu-screen-recorder -sc calls this with: $1 = file path, $2 = type
# ("regular" | "replay" | "screenshot").
#
# Style: $NOCTALIA_REC_STYLE wins, otherwise STYLE below.
#   num-date  ->  Запись 001 — 2026-10-18 13-44-51.mp4   (default)
#   num       ->  Запись 001.mp4
#   date      ->  2026-10-18 13-44-51.mp4   (no counter)
#   en        ->  Recording 001 — 2026-10-18 13-44-51.mp4
# Replay-buffer saves get Повтор/Replay instead of Запись/Recording.
#
# The counter is "next free number in the target directory", so deleting clips
# reuses their numbers only if the gap is at the end; otherwise it just counts on.

STYLE="${NOCTALIA_REC_STYLE:-${STYLE:-num-date}}"

src="${1:-}"
kind="${2:-regular}"
[ -n "$src" ] && [ -f "$src" ] || exit 0
[ "$kind" = "screenshot" ] && exit 0

stem="${src##*/}"
case "$stem" in
    # Already renamed (number + " — " or bare number). Quoted literals keep
    # "Запись 2026-10-18 13-52-59.mp4" (the plugin's own pattern) out of this.
    "Запись "[0-9][0-9][0-9]" —"* | "Запись "[0-9][0-9][0-9]".mp4" | \
    "Повтор "[0-9][0-9][0-9]" —"* | "Повтор "[0-9][0-9][0-9]".mp4" | \
    "Recording "[0-9][0-9][0-9]" —"* | "Recording "[0-9][0-9][0-9]".mp4" | \
    "Replay "[0-9][0-9][0-9]" —"* | "Replay "[0-9][0-9][0-9]".mp4")
        exit 0 ;;
esac

# Leave the recorder's own name in place for a moment: the Noctalia service
# reports "Recording saved <path>" from that exact path 0.5s after the stop.
sleep 2

dir=$(dirname -- "$src")
ext="${src##*.}"
stamp=$(date -r "$src" '+%Y-%m-%d %H-%M-%S')

case "$kind" in
    replay) prefix_ru="Повтор";  prefix_en="Replay" ;;
    *)      prefix_ru="Запись";  prefix_en="Recording" ;;
esac

if [ "$STYLE" = "date" ]; then
    target="$dir/$stamp.$ext"
    n=2
    while [ -e "$target" ]; do
        target="$dir/$stamp ($n).$ext"
        n=$((n + 1))
    done
else
    if [ "$STYLE" = "en" ]; then prefix="$prefix_en"; else prefix="$prefix_ru"; fi
    n=1
    while :; do
        num=$(printf '%03d' "$n")
        case "$STYLE" in
            num) target="$dir/$prefix $num.$ext" ;;
            *)   target="$dir/$prefix $num — $stamp.$ext" ;;
        esac
        # A number is taken if any clip with that number exists, under either
        # prefix and whichever style it was named in.
        taken=$(ls -d -- "$dir/$prefix_ru $num"* "$dir/$prefix_en $num"* 2>/dev/null | head -n 1)
        [ -n "$taken" ] || break
        n=$((n + 1))
    done
fi

mv -n -- "$src" "$target" || exit 0
printf '%s\n' "$target"
