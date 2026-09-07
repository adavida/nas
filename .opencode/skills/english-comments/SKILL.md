---
name: english-comments
description: Enforce English-only comments and docs. Use when writing, editing, or reviewing code comments, Nix docs, or markdown — translates/rejects French comments.
---

# English Comments

All code comments, Nix docstrings, and markdown prose must be in English.

## Rules

- Comments (`#`, `//`, `/* */`, `--`, `/*`) must be English. Translate French on sight.
- No French in commit messages, `AGENTS.md`, `MIGRATION.md`, `readme.md` unless quoted.
- When editing a file with French comments, translate them in the same diff — don't leave mixed languages.
- Keep technical terms verbatim (e.g., `clamd.ctl`, `av_host`), only translate surrounding prose.

## When triggered

- User says "commentaire en anglais", "english comments", or any edit touches a comment.
- Review: grep for `[àâéèêëïîôùûç]` in `*.nix`/`*.md` and flag.

## Example

```nix
# bad
# files_antivirus en mode daemon socket a besoin de lire /run/clamav/clamd.ctl

# good
# files_antivirus in daemon socket mode needs read access to /run/clamav/clamd.ctl
```

Pattern: `French comment → English comment in same diff, no separate commit.`
