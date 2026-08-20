---
name: suggst-task
description: Execute development tasks on Suggst with lightweight, focused, minimal-token approach. Automatically applies preservation, minimal reading, targeted validation, and recovery rules.
---

# /suggst-task — Lightweight development task

You are executing a development task on Suggst v2 (Swift 6.2, SwiftUI, macOS).

**Read and apply the policy at `.agents/skills/suggst-task/POLICY.md` first.**

The policy governs:
1. Which files to read (minimal).
2. How to validate changes (proportioned).
3. How to handle failures (retry hypothesis once, then abandon).
4. When to claim success (evidence required).
5. When to request manual action (impossible-to-automate only).

## Quick execution flow

1. **Determine mode** from the task (ANALYSE, CORRECTION, IMPLEMENTATION, DOCUMENTATION, VALIDATION).
   - Print mode in one line, no verbose preamble.

2. **Read minimally** per policy.
   - Only files directly affected + 1–2 neighbors for pattern.
   - Read full spec only if task touches contracts, gates, architecture, or requirements.

3. **Execute the task** respecting conventions:
   - Targeted edits.
   - No refactoring or abstraction.
   - Preserve all unrelated changes.
   - No commits or pushes.

4. **Validate proportionally**:
   - Use `./scripts/build.sh` after code changes.
   - Use `./scripts/verify.sh` only before final report or on explicit request.
   - Use targeted tests for analysis.

5. **Report concisely**:
   - Cause/result.
   - Files modified.
   - Validation evidence.
   - Remaining action.
   - Git state.

## Canonical references

- **Specifications**: `docs/rebuild/steps/STEP-*.md`
- **Conventions**: `CLAUDE.md`, `AGENTS.md`
- **Architecture**: `docs/CONTEXT.md`
- **Build scripts**: `./scripts/build.sh`, `./scripts/verify.sh`
- **Canonical paths**: see `AGENTS.md`
- **Project structure**: see `AGENTS.md` → "Project structure"

## If unsure about mode

**ANALYSE** if the task is:
- "Debug why X fails"
- "Analyze this log"
- "What's the root cause?"
- "Review the architecture for X"

**CORRECTION** if the task is:
- "Fix the button overflow in SessionPreparationView"
- "The audio capture drops frames, fix it"
- "Resolve the build error in AudioProvider"

**IMPLEMENTATION** if the task is:
- "Add a progress bar to the interview flow"
- "Implement the microphone selector"
- "Create a diagnostic export feature"

**DOCUMENTATION** if the task is:
- "Update the architecture diagram"
- "Document the capture lifecycle"
- "Add examples to the brick registry"

**VALIDATION** if the task is:
- "Run the full test suite"
- "Validate STEP-03 manually per the guide"
- "Check whether verify.sh passes"

---

## Do not ask the user for context already in the repo

Example of incorrect behavior:
```
What is the exact error message in AudioProvider?
```

Correct behavior:
```
[reads the relevant logs or files]
I found the issue: AudioProvider initializes AVAudioEngine twice.
```

---

## When two hypotheses fail on the same strategy, abandon it

Example:
- Hypothesis: "The issue is the buffer size."
  - Attempt 1: change buffer size → fails.
  - Attempt 2: change buffer size differently → fails.
  - **Action**: stop changing buffer size. Remove those changes. Propose a different strategy (e.g., the issue is actually the callback timing).

Do not retry the same hypothesis with minor variations; move to a different root cause.

---

## Success criteria

The task is complete when:
- **ANALYSE**: probable cause stated, evidence shown, next action given.
- **CORRECTION**: minimal fix applied, targeted validation passed, final `verify.sh` passed (if code touched).
- **IMPLEMENTATION**: spec implemented per contract, tests pass, final `verify.sh` passed.
- **DOCUMENTATION**: docs updated and cross-checked, no build needed (unless docs influence code).
- **VALIDATION**: validation executed at requested level, results reported.

---

## Syntax

```
/suggst-task <free-form task description>
```

Examples:
```
/suggst-task Fix the microphone permission denial in AudioProvider.swift.

/suggst-task Analyze why the capture drops 20% of audio frames.

/suggst-task Add French interface strings for the new device selector.

/suggst-task Update the architecture doc to clarify the ring buffer lifecycle.

/suggst-task Validate STEP-03 according to the manual test guide.
```

---

The policy is the single source of truth. Load it once, apply it consistently, and never mention it in the output unless a rule is being violated.
