#!/bin/bash
# Lints prose Claude writes for AI tells using Vale + vale-ai-tells.
#
# PostToolUse on Write/Edit: lints .md/.txt/.mdx files, feeds flags back so Claude fixes them.
# PreToolUse on outbound MCP tools (Slack, Gmail, Notion, Docs): blocks the send once with
#   the flags. Resending identical content goes through, so a false positive can't loop.

CONFIG="$HOME/.claude/vale/.vale.ini"
SEEN_DIR="${TMPDIR:-/tmp}/claude-slop-check"
mkdir -p "$SEEN_DIR"

command -v vale >/dev/null || exit 0
input=$(cat)
event=$(jq -r '.hook_event_name' <<<"$input")
tool=$(jq -r '.tool_name' <<<"$input")

if [[ "$event" == "PostToolUse" ]]; then
  file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
  [[ "$file" =~ \.(md|txt|mdx)$ ]] || exit 0
  # Skip Claude's own memory/config and dependency folders
  [[ "$file" == "$HOME/.claude/"* || "$file" == *node_modules* || "$file" == *CHANGELOG* ]] && exit 0
  [[ -f "$file" ]] || exit 0
  out=$(vale --config "$CONFIG" --output=line "$file" 2>/dev/null | cut -d: -f2,4- | head -25)
  [[ -z "$out" ]] && exit 0
  echo "AI-writing tells in $file (rewrite these; if one is a false positive, leave it):" >&2
  echo "$out" >&2
  exit 2
fi

if [[ "$event" == "PreToolUse" ]]; then
  # Pull every string field longer than 40 chars (skips IDs, channel names, etc.)
  text=$(jq -r '[.tool_input | .. | strings | select(length > 40)] | join("\n\n")' <<<"$input")
  [[ -z "$text" ]] && exit 0
  hash=$(printf %s "$text" | shasum | cut -c1-16)
  [[ -f "$SEEN_DIR/$hash" ]] && exit 0
  tmp="$SEEN_DIR/$hash.md"
  printf %s "$text" > "$tmp"
  out=$(vale --config "$CONFIG" --output=line "$tmp" 2>/dev/null | cut -d: -f2,4- | head -25)
  rm -f "$tmp"
  [[ -z "$out" ]] && exit 0
  touch "$SEEN_DIR/$hash"
  echo "Blocked $tool: AI-writing tells found (line:rule:message). Rewrite and resend. If they're false positives, resend unchanged and it will go through:" >&2
  echo "$out" >&2
  exit 2
fi
exit 0
