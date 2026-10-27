#!/bin/bash
# Sets up humanizer + Vale ai-tells + the slop-check hook for Claude Code.
# Safe to re-run: it skips anything already in place and backs up settings.json first.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
SETTINGS="$CLAUDE/settings.json"
HOOK_CMD="~/.claude/hooks/slop-check.sh"
OUTBOUND='mcp__claude_ai_Slack__slack_(send_message|send_message_draft|schedule_message|create_canvas|update_canvas)|mcp__claude_ai_Gmail__(send_message|reply|forward|create_draft|update_draft)|mcp__claude_ai_Notion__notion-(create-pages|update-page|create-comment)|mcp__claude_ai_Claude_Docs__(batch|update)'

say() { printf '\n==> %s\n' "$1"; }

say "Checking for vale and jq"
for tool in vale jq; do
  if ! command -v "$tool" >/dev/null; then
    if command -v brew >/dev/null; then
      brew install "$tool"
    else
      echo "Install $tool first (https://vale.sh/docs/install, https://jqlang.org/download), then re-run." >&2
      exit 1
    fi
  fi
done

mkdir -p "$CLAUDE/hooks" "$CLAUDE/vale" "$CLAUDE/voice" "$CLAUDE/skills"

say "Installing the slop-check hook"
cp "$REPO/hooks/slop-check.sh" "$CLAUDE/hooks/slop-check.sh"
chmod +x "$CLAUDE/hooks/slop-check.sh"

say "Setting up Vale with the ai-tells rules"
if [[ -f "$CLAUDE/vale/.vale.ini" ]]; then
  echo "Keeping your existing $CLAUDE/vale/.vale.ini"
else
  cp "$REPO/vale/.vale.ini" "$CLAUDE/vale/.vale.ini"
fi
(cd "$CLAUDE/vale" && vale sync)

say "Installing the build-voice skill"
rm -rf "$CLAUDE/skills/build-voice"
cp -R "$REPO/skills/build-voice" "$CLAUDE/skills/build-voice"

say "Updating $SETTINGS"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
tmp=$(mktemp)
jq --arg cmd "$HOOK_CMD" --arg outbound "$OUTBOUND" '
  def add_hook($event; $matcher):
    if ([.hooks[$event][]?.hooks[]?.command] | index($cmd)) then .
    else .hooks[$event] += [{matcher: $matcher, hooks: [{type: "command", command: $cmd, timeout: 30}]}]
    end;
  .extraKnownMarketplaces.humanizer = {source: {source: "github", repo: "blader/humanizer"}}
  | .enabledPlugins["humanizer@humanizer"] = true
  | .hooks //= {}
  | add_hook("PostToolUse"; "Write|Edit|MultiEdit")
  | add_hook("PreToolUse"; $outbound)
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

say "Adding writing rules to $CLAUDE/CLAUDE.md"
if grep -q "voice/samples.md" "$CLAUDE/CLAUDE.md" 2>/dev/null; then
  echo "Already there, skipping"
else
  { [[ -s "$CLAUDE/CLAUDE.md" ]] && echo; cat "$REPO/templates/CLAUDE.md"; } >> "$CLAUDE/CLAUDE.md"
fi

cat <<'EOF'

Done. Last step: open Claude Code and run

  /build-voice

It asks where your writing is (Google Drive, Slack, Gmail, a folder), pulls
real samples, writes ~/.claude/voice/samples.md, and tunes Vale so it stops
flagging your own habits. Restart Claude Code first if it was already open.
EOF
