---
name: build-voice
description: Build the user's voice sample file (~/.claude/voice/samples.md) from their real writing in Google Drive, Slack, Gmail, or a local folder, then tune the Vale ai-tells rules so they don't flag the user's own style. Use when the user says "build my voice", "set up my voice sample", "point it at my drive", or runs /build-voice.
---

# Build a voice sample

The humanizer skill matches a writing sample when it has one. This skill builds that sample from the user's own writing. With it, rewrites sound like the user instead of a generic "human."

Output: `~/.claude/voice/samples.md`. Then the Vale config at `~/.claude/vale/.vale.ini` gets tuned against it.

## 1. Ask where their writing is

Ask once, in one message:

- Which sources to use. Offer whatever is connected in this session: Google Drive, Slack, Gmail (sent mail only), Notion, plus any local folder or export they point to, like a Google Takeout zip or a folder of old essays.
- Their name as it appears in those tools, so you only pull what they wrote.
- Anything to skip. Docs they know were AI-written and group projects with mixed authorship are the usual ones.

If a source they want isn't connected, tell them which connector to add and continue with the rest.

## 2. Collect real writing

Search each source for things the user wrote alone. Good material, in order:

1. Long-form they wrote before 2023 (essays, blog posts, papers, memos). This is the cleanest signal because it predates AI drafting tools.
2. Recent work writing, like Slack threads they started, sent emails, and docs they own alone.
3. Short replies and asks, for the casual register.

Skip anything that reads AI-written (heavy em dashes, "not X but Y" contrasts, bold-label bullets, "I hope this finds you well"). If you're unsure, list it and ask. Aim for 15 to 30 excerpts, 2,000 to 5,000 words total. Quote excerpts verbatim. Don't fix typos or "improve" anything. The humanizer needs the quirks to match them.

Never paste these excerpts anywhere outside the local file.

## 3. Write the samples file

Write `~/.claude/voice/samples.md` in this format:

```markdown
# <Name>'s writing samples

Real writing by <Name>, used as the humanizer skill's voice sample. Registers: <e.g. long-form (2018-2022) and work Slack (2026)>.

Sources excluded: <what the user asked to skip>.

## How <Name> writes (read this first)

- 8 to 12 bullets, each a concrete habit with a short quote from the excerpts as proof.
  Cover: how they open, how they argue, how they hedge, punctuation habits
  (parentheses? dashes? semicolons?), sentence length, structure words,
  how they end, and how the casual register differs.

## Long-form

### <short label> (<year>)

<verbatim excerpt>

## Work / casual

### <short label>

<verbatim excerpt>
```

If the user wants to override a habit in their old writing (for example "I used dashes a lot, I don't want them anymore"), put that at the top as an **Override:** line and follow it.

Show the user the "How <Name> writes" bullets and ask if anything's off. Fix what they flag.

## 4. Tune Vale against their writing

The ai-tells rules flag patterns models overuse, but some of those patterns are normal for a person. Run:

```bash
vale --config ~/.claude/vale/.vale.ini --output=JSON ~/.claude/voice/samples.md
```

Count alerts by rule. A rule that matches 3+ times in the user's real writing is part of their voice, so turn it off by appending `ai-tells.<RuleName> = NO` under the `[*.{md,txt,mdx}]` section of `~/.claude/vale/.vale.ini`. For rules that match once or twice, show the user the flagged lines and let them decide.

Tell the user which rules you turned off and why.

## 5. Check it works

Write a short paragraph on any topic in the user's voice using the humanizer skill with the new sample, and show it to them. Ask whether it sounds like them. If not, ask what's wrong and adjust the "How <Name> writes" bullets.
