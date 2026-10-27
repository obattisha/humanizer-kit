# humanizer-kit

My setup for getting Claude Code to write like me instead of like Claude. One script installs it, then you point Claude at your Google Drive (or Slack, Gmail, a folder of old essays) and it builds a voice sample from your real writing.

## What you get

1. **The [humanizer](https://github.com/blader/humanizer) skill** (by Siqi Chen). It rewrites text to strip AI tells. When it has a sample of your writing it matches that instead of a generic voice.
2. **A voice sample built from your own writing** at `~/.claude/voice/samples.md`. The `/build-voice` skill in this repo makes it for you.
3. **Vale with the [ai-tells](https://github.com/tbhb/vale-ai-tells) rules** as a hook. When Claude writes a `.md`/`.txt` file, or tries to send a Slack message, email, Notion page, or Claude Doc, Vale checks it and makes Claude fix whatever sounds AI-written. If something it flags is a false positive, Claude resends it unchanged and it goes through (so it can't get stuck in a loop).
4. **A few lines in `~/.claude/CLAUDE.md`** telling Claude to use all of the above on anything outbound.

## Setup

You need Claude Code. On a Mac the script installs `vale` and `jq` with Homebrew.

```bash
git clone https://github.com/obattisha/humanizer-kit.git
```

```bash
./humanizer-kit/install.sh
```

The script backs up your `settings.json` before touching it and skips anything you already have, so re-running it is fine.

Then restart Claude Code and run:

```
/build-voice
```

It'll ask where your writing is and what to skip. Connect Google Drive, Slack, or Gmail in Claude first if you want it to pull from them. Older writing (pre-2023 essays, blog posts, school papers) works best, since none of it went through an AI. It then:

- pulls 15 to 30 excerpts of things you wrote yourself, verbatim
- writes a short "how you write" summary at the top and asks you to correct it
- runs Vale on your samples and turns off any rule that flags your own habits (if you naturally use semicolons, it stops yelling about semicolons)
- writes a test paragraph so you can check it sounds like you

## Tweaking it

- **Want to drop a habit?** Add an `**Override:**` line at the top of `samples.md`. Mine says to never use em dashes even though I used them constantly in 2019.
- **A Vale rule keeps flagging stuff that's fine?** Add `ai-tells.RuleName = NO` to `~/.claude/vale/.vale.ini`.
- **Using different connectors?** The outbound-message check matches tool names in the `PreToolUse` matcher for `slop-check.sh` in `~/.claude/settings.json`. Add yours to that regex.

Your samples file stays on your machine. The scripts here only write to `~/.claude`.
