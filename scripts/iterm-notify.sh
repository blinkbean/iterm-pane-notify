#!/bin/bash
# iterm-notify.sh — flag the current iTerm2 pane when Claude Code wants you.
#   done     : save current bg+fg once, then switch to the attention colors
#   reset    : restore the saved bg+fg
#   preview  : cycle all candidates live in THIS pane to calibrate by eye, then restore
# Only touches the pane THIS claude runs in, matched via $ITERM_SESSION_ID,
# so sibling split panes are never affected.

action="$1"
sid="${ITERM_SESSION_ID##*:}"
[ "$TERM_PROGRAM" = "iTerm.app" ] || exit 0   # not iTerm2 -> no-op
[ -n "$sid" ] || exit 0

state="/tmp/claude-iterm-bg-${sid}"
# Last-known TRUE original bg+fg, keyed per iTerm2 PROFILE (NOT shared across
# all panes). A pane split (Ctrl+D) out of an attention-colored parent is born
# showing the attention color with no state of its own; it falls back to this
# to recover its real original. Keying by profile means a split child — which
# inherits the parent's profile — restores to the right color, while panes on a
# different profile can no longer clobber each other's fallback (the old shared
# file was the one cross-pane coupling that let a new session inherit an old
# one's restore color).
default_file="/tmp/claude-iterm-bg-default-${ITERM_PROFILE:-_noprofile}"

# Candidates, RGB each 0-65535 (= hex channel * 257). Tip: trust iTerm2's look,
# not a browser swatch — run `iterm-notify.sh preview` to compare them in-pane.
CANDIDATES=(
  "深钢蓝 steel  #005488=0, 21588, 34952"
  "VS Code 蓝    #007ACC=0, 31354, 52428"
  "深青 teal     #00695C=0, 26985, 23644"
  "深靛蓝 indigo #3F3D77=16191, 15677, 30583"
  "柔紫 purple   #5E4B8B=24158, 19275, 35723"
  "森林绿 forest #2F6B2F=12079, 27499, 12079"
  "勃艮第红 burg #6B2737=27499, 10023, 14135"
  "石板灰蓝 slate#37474F=14135, 18247, 20303"
)

# Active attention colors. Pick a background from CANDIDATES above.
ATTENTION_BG="0, 26985, 23644"          # 深青 #00695C
ATTENTION_FG="65535, 65535, 65535"      # white text, high contrast on any candidate

# True if "$1" (an "r, g, b" string) matches ATTENTION_BG within a tolerance.
# iTerm2 quantizes a color set via AppleScript by ±1 per channel (e.g. we set
# 23644 but read back 23643), so an exact string compare is unreliable and was
# silently breaking both the done-guard and the reset fallback. 64 absorbs that
# jitter yet stays far below the >1000 gap between any two candidate colors.
bg_is_attention() {
  local in="$1" tol=64 r1 g1 b1 r2 g2 b2 dr dg db
  IFS=', ' read -r r1 g1 b1 <<<"$in"
  IFS=', ' read -r r2 g2 b2 <<<"$ATTENTION_BG"
  [ -n "$r1" ] && [ -n "$g1" ] && [ -n "$b1" ] || return 1
  dr=$(( r1>r2 ? r1-r2 : r2-r1 )); dg=$(( g1>g2 ? g1-g2 : g2-g1 )); db=$(( b1>b2 ? b1-b2 : b2-b1 ))
  [ "$dr" -le "$tol" ] && [ "$dg" -le "$tol" ] && [ "$db" -le "$tol" ]
}

find_and() {
  # $1 = AppleScript run with the matched session bound to `s`
  osascript 2>/dev/null <<APPLESCRIPT
tell application "iTerm2"
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        if (id of s) is "${sid}" then
          ${1}
        end if
      end repeat
    end repeat
  end repeat
end tell
APPLESCRIPT
}

read_colors() {
  # prints "bg_r, bg_g, bg_b|fg_r, fg_g, fg_b"
  find_and 'set {br, bg, bb} to background color of s
      set {fr, fg, fb} to foreground color of s
      return (br as string) & ", " & (bg as string) & ", " & (bb as string) & "|" & (fr as string) & ", " & (fg as string) & ", " & (fb as string)'
}

case "$action" in
  done)
    if [ ! -f "$state" ]; then
      cur=$(read_colors)
      curbg="${cur%%|*}"
      # Guard: don't save the attention bg as "original" (prior crash / no reset,
      # or a pane split out of an already-colored parent).
      if [ -n "$curbg" ] && ! bg_is_attention "$curbg"; then
        printf '%s' "$cur" > "$state"
        printf '%s' "$cur" > "$default_file"   # remember the TRUE original for split-born panes
      fi
    fi
    find_and "set background color of s to {${ATTENTION_BG}}"
    find_and "set foreground color of s to {${ATTENTION_FG}}"
    ;;
  reset)
    if [ -f "$state" ]; then
      saved=$(cat "$state")
      bg="${saved%%|*}"; fg="${saved##*|}"
      [ -n "$bg" ] && find_and "set background color of s to {${bg}}"
      [ -n "$fg" ] && [ "$fg" != "$bg" ] && find_and "set foreground color of s to {${fg}}"
      rm -f "$state"
    elif [ -f "$default_file" ]; then
      # No state of our own. If this pane is currently showing the attention
      # color, it was almost certainly split (Ctrl+D) out of a colored parent
      # and is stuck there — restore it from the shared true-original default.
      cur=$(read_colors)
      curbg="${cur%%|*}"
      if [ -n "$curbg" ] && bg_is_attention "$curbg"; then
        saved=$(cat "$default_file")
        bg="${saved%%|*}"; fg="${saved##*|}"
        [ -n "$bg" ] && find_and "set background color of s to {${bg}}"
        [ -n "$fg" ] && [ "$fg" != "$bg" ] && find_and "set foreground color of s to {${fg}}"
      fi
    fi
    ;;
  preview)
    cur=$(read_colors)
    curbg="${cur%%|*}"; curfg="${cur##*|}"
    echo "Cycling ${#CANDIDATES[@]} candidates in this pane (2.2s each)…"
    for entry in "${CANDIDATES[@]}"; do
      name="${entry%%=*}"; rgb="${entry#*=}"
      find_and "set background color of s to {${rgb}}"
      find_and "set foreground color of s to {${ATTENTION_FG}}"
      printf '  %-16s %s\n' "$name" "$rgb"
      sleep 2.2
    done
    find_and "set background color of s to {${curbg}}"
    find_and "set foreground color of s to {${curfg}}"
    echo "restored."
    ;;
  *)
    echo "usage: $0 {done|reset|preview}" >&2
    exit 2
    ;;
esac
exit 0
