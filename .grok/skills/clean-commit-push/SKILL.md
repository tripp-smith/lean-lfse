---
name: clean-commit-push
description: >
  Automates the end-of-session "notes + cleanup + commit + push" workflow.
  Use when the user says things like: "cleanup commit push", "notes and push", 
  "release notes then commit", "do the ccp thing", "/ccp", "finish and push",
  or after completing a significant body of work.
  Also known as ccp or clean-commit-push.
metadata:
  short-description: "Notes, cleanup temp files, commit, and push"
  aliases: ["ccp"]
---

# Clean Commit Push (ccp)

This skill helps you properly close out a work session by:

- Capturing good notes / release notes about what was accomplished
- Cleaning up temporary and scratch files into `_tmp/`
- Updating `.gitignore` when needed
- Writing a high-quality commit message
- Committing and pushing cleanly

## When to Use

Trigger this skill when the user wants to:
- Wrap up implementation work
- Document what was done before pushing
- Clean up temp files before committing
- Create proper release / session notes

## Workflow

Follow these steps in order:

### 1. Gather Context (Autonomous by Default)
- **First, act autonomously**: Run `git status`, `git diff --name-only`, `git log --oneline -10`, and inspect recently changed files yourself.
- Synthesize a draft summary of what was likely accomplished in the session based on the actual code changes.
- Only ask the user for clarification or corrections if the analysis is ambiguous or incomplete.
- When the user says phrases like "do it for me", "go", "just do it", or "the skill should do this automatically", minimize questions and drive the process forward with your own analysis.

### 2. Create / Update Notes
- Help the user write clear release notes or a session summary.
- Recommended locations (in priority order):
  1. `_tmp/SESSION_YYYY-MM-DD_<short-description>.md` (for detailed implementation notes)
  2. Update `CHANGELOG.md` under `## Unreleased`
  3. Enhance the relevant section in `README.md`
- The notes should typically include:
  - What was built / changed
  - Key decisions or gotchas
  - Model used (if relevant, e.g. Grok 4.3)
  - Rough effort / token usage (when doing large agentic sessions)

### 3. Cleanup Temporary Files
- Scan the repository for common temporary artifacts:
  - Files with `.tmp`, `.temp`, `~` suffixes
  - Scratch files in root or random locations
  - Build artifacts that shouldn't be committed
  - Session logs or notes left in the wrong place
- Propose moving appropriate files/directories into `_tmp/`.
- Create `_tmp/` if it doesn't exist.

### 4. Update .gitignore
- Ensure `_tmp/` (or `_tmp`) is ignored.
- Add any new temporary patterns discovered during cleanup.
- Show the user the diff before modifying `.gitignore`.

### 5. Prepare the Commit
- Show the user a summary of files that will be committed (`git status`).
- Draft a high-quality conventional commit message. Good structure:
  ```
  type(scope): short summary

  - Bullet of key changes
  - Another bullet
  - Notes about testing / verification

  (Optional: reference to _tmp/ session notes)
  ```
- Let the user edit the message before committing.

### 6. Commit and Push
- Run `git add -A`
- Commit with the approved message
- Push to the current branch's upstream
- Show the final commit hash and a success message

## Safety Rules

- Always show `git status` and proposed changes before committing.
- Never force-push unless explicitly asked.
- If there are uncommitted changes the user might want to review, pause and ask.
- If the working tree is already clean, inform the user and ask what they want to do instead.

## Example Invocation

User: "ccp" or "do it for me"

Agent behavior (preferred):
1. Autonomously inspect `git status`, recent diffs, and changed files.
2. Generate a draft session note in `_tmp/SESSION_....md`.
3. Propose updates to CHANGELOG.md / README.md as appropriate.
4. Draft a high-quality commit message.
5. Show a clear summary of proposed changes + commit message.
6. Ask for final confirmation only on the commit message and whether to push.
7. Execute commit + push.

The skill should be proactive and only interrupt the user when genuinely uncertain.

## Tips for Best Results

- The skill is designed to be **autonomous by default**. When the user says "go", "do it for me", or simply "/ccp", lead with your own analysis of the changes rather than immediately asking questions.
- Run this skill **before** the user gets distracted and forgets the details of the session.
- The `_tmp/` directory is the preferred home for detailed implementation notes that don't belong in the permanent docs.
- This skill pairs very well with long agentic coding sessions (especially those involving Grok or other LLMs).