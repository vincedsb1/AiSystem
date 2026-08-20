#!/usr/bin/env bash
set -euo pipefail

# AI System Action Backend
# Supports two UI modes:
# - terminal: opens Terminal for long-running commands (default)
# - app: runs in background, logs output, returns exit code (for GUI)

AI_SYSTEM_ROOT="/Users/vincentdesbrosses/Documents/Misc/ai-system"
LOGS_DIR="$AI_SYSTEM_ROOT/logs"
LAST_LOG="$LOGS_DIR/ai-system-last-action.log"
UI_MODE="${AI_SYSTEM_UI_MODE:-terminal}"

# === Utilities ===

ensure_logs_dir() {
  mkdir -p "$LOGS_DIR"
}

run_in_terminal() {
  local command="$1"
  osascript << EOF
tell application "Terminal"
  do script "cd '$AI_SYSTEM_ROOT' && $command"
  activate
end tell
EOF
}

run_in_app_mode() {
  local command="$1"
  ensure_logs_dir

  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local exit_code=0

  {
    echo "=== AI System Action Log ==="
    echo "Timestamp: $timestamp"
    echo "Action: $command"
    echo "Mode: app"
    echo "---"
    cd "$AI_SYSTEM_ROOT" && eval "$command" || exit_code=$?
  } > "$LAST_LOG" 2>&1 || exit_code=$?

  return $exit_code
}

run_in_swift_mode() {
  local command="$1"
  ensure_logs_dir

  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_out="$LOGS_DIR/ai-system-last-action-out.log"
  local log_err="$LOGS_DIR/ai-system-last-action-err.log"

  {
    echo "=== AI System Action Log ==="
    echo "Timestamp: $timestamp"
    echo "Action: $command"
    echo "Mode: swift"
    echo "---"
  } | tee "$log_out" "$LAST_LOG" > /dev/null
  : > "$log_err"

  local exit_code=0
  { cd "$AI_SYSTEM_ROOT" && eval "$command"; } \
    > >(tee -a "$log_out" "$LAST_LOG") \
    2> >(tee -a "$log_err" "$LAST_LOG" >&2)
  exit_code=$?

  return $exit_code
}

# Safe argv-based runners for machine-readable backend routes.  Keep the
# legacy string runners above for existing actions, but never use them for
# project discovery/scanning: user arguments must remain separate argv items.
run_argv_in_app_mode() {
  local -a command=("$@")
  ensure_logs_dir

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  {
    echo "=== AI System Action Log ==="
    echo "Timestamp: $timestamp"
    printf 'Action:'
    printf ' %q' "${command[@]}"
    echo
    echo "Mode: app"
    echo "---"
  } > "$LAST_LOG"

  local exit_code=0
  if (cd "$AI_SYSTEM_ROOT" && "${command[@]}" \
    > >(tee -a "$LAST_LOG") \
    2> >(tee -a "$LAST_LOG" >&2)); then
    exit_code=0
  else
    exit_code=$?
  fi
  return "$exit_code"
}

run_argv_in_swift_mode() {
  local -a command=("$@")
  ensure_logs_dir

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_out="$LOGS_DIR/ai-system-last-action-out.log"
  local log_err="$LOGS_DIR/ai-system-last-action-err.log"

  {
    echo "=== AI System Action Log ==="
    echo "Timestamp: $timestamp"
    printf 'Action:'
    printf ' %q' "${command[@]}"
    echo
    echo "Mode: swift"
    echo "---"
  } | tee "$log_out" "$LAST_LOG" > /dev/null
  : > "$log_err"

  local exit_code=0
  if (cd "$AI_SYSTEM_ROOT" && "${command[@]}" \
    > >(tee -a "$log_out" "$LAST_LOG") \
    2> >(tee -a "$log_err" "$LAST_LOG" >&2)); then
    exit_code=0
  else
    exit_code=$?
  fi
  return "$exit_code"
}

run_project_backend() {
  local subcommand="$1"
  shift
  local -a command=(
    "$AI_SYSTEM_ROOT/.venv/bin/python"
    "$AI_SYSTEM_ROOT/scripts/project_skills.py"
    "$subcommand"
    "$@"
    "--json"
  )

  case "$UI_MODE" in
    app)
      run_argv_in_app_mode "${command[@]}"
      ;;
    swift)
      run_argv_in_swift_mode "${command[@]}"
      ;;
    terminal|*)
      (cd "$AI_SYSTEM_ROOT" && "${command[@]}")
      ;;
  esac
}

execute_action() {
  local command="$1"

  if [[ "$UI_MODE" == "app" ]]; then
    run_in_app_mode "$command"
  elif [[ "$UI_MODE" == "swift" ]]; then
    run_in_swift_mode "$command"
  else
    run_in_terminal "$command"
  fi
}

open_file() {
  local file="$1"
  local full_path="$AI_SYSTEM_ROOT/$file"

  if [[ ! -e "$full_path" ]]; then
    echo "Error: file not found: $full_path" >&2
    exit 1
  fi

  open "$full_path"
}

show_usage() {
  cat << 'EOF'
Usage:
  ai_system_action.sh <action>
  ai_system_action.sh install-project <project> <targets>
  ai_system_action.sh project-list
  ai_system_action.sh project-scan <project>

Environment variables:
  AI_SYSTEM_UI_MODE=app       Run in app mode (no Terminal, write logs, merged stdout/stderr)
  AI_SYSTEM_UI_MODE=swift     Run in Swift GUI mode (no Terminal, separate stdout/stderr streams + logs)
  AI_SYSTEM_UI_MODE=terminal  Run in Terminal mode (default)

System Validation:
  check              Run full system check (make check)
  inventory          Run inventory scan (make inventory)
  doctor             Run health audit (make doctor)

Exports & Sync:
  update             Update all projects (Claude + Codex)
  update-codex       Update Codex exports only
  update-claude      Update Claude exports only
  install-project    Install/update a specific project (requires PROJECT TARGETS args)

Reports:
  open-inventory     Open Inventory report
  open-doctor        Open Doctor report
  open-log           Open last action log

Documentation:
  open-readme        Open README.md
  open-operations    Open OPERATIONS.md
  open-skill-workflow Open SKILL-WORKFLOW.md
  open-project-onboarding Open PROJECT-ONBOARDING.md
  open-plan          Open Plan-AI-System.md
  open-local-gui-design Open LOCAL-GUI-DESIGN.md

Configuration:
  install-hooks      Install local pre-commit hook
  git-status         Show git status

Shortcuts:
  open-cursor        Open repo in Cursor
  open-terminal      Open Terminal in repo
  open-finder        Open Finder in repo

Project Management:
  add-project        Add new project (requires PROJECT PATH TARGETS INSTALL_NOW args)
  project-list       List active registered projects as JSON
  project-scan       Scan one registered project as JSON (read-only)

GUI App Building:
  build-gui-app      Build/rebuild AI System.app (AppleScript) with icon
  build-swift-app    Build/install AI System.app (SwiftUI) to ~/Applications
EOF
}

# === Actions ===

action_check() {
  execute_action "make check"
}

action_inventory() {
  execute_action "make inventory"
}

action_doctor() {
  execute_action "make doctor"
}

action_update() {
  execute_action "make update-projects TARGETS=both && echo '' && echo 'Validation...' && sleep 2 && make check"
}

action_update_codex() {
  execute_action "make update-projects TARGETS=codex && echo '' && echo 'Validation...' && sleep 2 && make check"
}

action_update_claude() {
  execute_action "make update-projects TARGETS=claude && echo '' && echo 'Validation...' && sleep 2 && make check"
}

action_install_project() {
  local project="$1"
  local targets="$2"

  if [[ -z "$project" || -z "$targets" ]]; then
    echo "Error: install-project requires PROJECT and TARGETS arguments" >&2
    echo "" >&2
    show_usage
    exit 1
  fi

  if [[ ! "$targets" =~ ^(codex|claude|both)$ ]]; then
    echo "Error: TARGETS must be one of: codex, claude, both" >&2
    exit 1
  fi

  execute_action "make install-project PROJECT=$project TARGETS=$targets && echo '' && echo 'Validation...' && sleep 2 && make check"
}

action_open_inventory() {
  open_file "reports/ai-inventory.latest.md"
}

action_open_doctor() {
  open_file "reports/ai-doctor.latest.md"
}

action_open_log() {
  if [[ ! -f "$LAST_LOG" ]]; then
    echo "No log file found at $LAST_LOG" >&2
    exit 1
  fi
  open "$LAST_LOG"
}

action_open_readme() {
  open_file "README.md"
}

action_open_operations() {
  open_file "docs/OPERATIONS.md"
}

action_open_skill_workflow() {
  open_file "docs/SKILL-WORKFLOW.md"
}

action_open_project_onboarding() {
  open_file "docs/PROJECT-ONBOARDING.md"
}

action_open_plan() {
  open_file "Plan-AI-System.md"
}

action_open_local_gui_design() {
  open_file "docs/LOCAL-GUI-DESIGN.md"
}

action_install_hooks() {
  execute_action "bash scripts/install_git_hooks.sh && echo '' && echo 'Hook installed locally.'"
}

action_git_status() {
  execute_action "git status"
}

action_open_cursor() {
  if ! command -v cursor >/dev/null 2>&1; then
    echo "Error: 'cursor' command not found in PATH" >&2
    exit 1
  fi
  cursor "$AI_SYSTEM_ROOT"
}

action_open_terminal() {
  open -a Terminal "$AI_SYSTEM_ROOT"
}

action_open_finder() {
  open "$AI_SYSTEM_ROOT"
}

action_add_project() {
  local project="$1"
  local project_path="$2"
  local targets="$3"
  local install_now="${4:-false}"

  if [[ -z "$project" || -z "$project_path" || -z "$targets" ]]; then
    echo "Error: add-project requires PROJECT PROJECT_PATH TARGETS INSTALL_NOW arguments" >&2
    exit 1
  fi

  if [[ ! "$targets" =~ ^(codex|claude|both)$ ]]; then
    echo "Error: TARGETS must be one of: codex, claude, both" >&2
    exit 1
  fi

  if [[ ! -d "$project_path" ]]; then
    echo "Error: Project path does not exist: $project_path" >&2
    exit 1
  fi

  execute_action ".venv/bin/python scripts/add_project.py --project '$project' --path '$project_path' --targets '$targets'"

  if [[ "$install_now" == "true" ]]; then
    execute_action "make install-project PROJECT='$project' TARGETS='$targets' && echo '' && echo 'Validation...' && sleep 2 && make check"
  fi
}

action_project_list() {
  if [[ $# -ne 0 ]]; then
    echo "Error: project-list does not accept arguments" >&2
    exit 1
  fi
  run_project_backend "list-projects"
}

action_project_scan() {
  if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: project-scan requires exactly one PROJECT argument" >&2
    exit 1
  fi
  run_project_backend "scan" "--project" "$1"
}

action_build_gui_app() {
  bash scripts/build_ai_system_app.sh
}

action_build_swift_app() {
  bash scripts/build_swift_app.sh
}

# === Main ===

if [[ $# -lt 1 ]]; then
  show_usage
  exit 1
fi

action="$1"
shift || true

case "$action" in
  check)
    action_check
    ;;
  inventory)
    action_inventory
    ;;
  doctor)
    action_doctor
    ;;
  update)
    action_update
    ;;
  update-codex)
    action_update_codex
    ;;
  update-claude)
    action_update_claude
    ;;
  install-project)
    if [[ $# -lt 2 ]]; then
      echo "Error: install-project requires PROJECT and TARGETS arguments" >&2
      exit 1
    fi
    action_install_project "$1" "$2"
    ;;
  open-inventory)
    action_open_inventory
    ;;
  open-doctor)
    action_open_doctor
    ;;
  open-log)
    action_open_log
    ;;
  open-readme)
    action_open_readme
    ;;
  open-operations)
    action_open_operations
    ;;
  open-skill-workflow)
    action_open_skill_workflow
    ;;
  open-project-onboarding)
    action_open_project_onboarding
    ;;
  open-plan)
    action_open_plan
    ;;
  open-local-gui-design)
    action_open_local_gui_design
    ;;
  install-hooks)
    action_install_hooks
    ;;
  git-status)
    action_git_status
    ;;
  open-cursor)
    action_open_cursor
    ;;
  open-terminal)
    action_open_terminal
    ;;
  open-finder)
    action_open_finder
    ;;
  add-project)
    if [[ $# -lt 3 ]]; then
      echo "Error: add-project requires PROJECT PROJECT_PATH TARGETS arguments" >&2
      exit 1
    fi
    action_add_project "$1" "$2" "$3" "${4:-false}"
    ;;
  project-list)
    action_project_list "$@"
    ;;
  project-scan)
    action_project_scan "$@"
    ;;
  build-gui-app)
    action_build_gui_app
    ;;
  build-swift-app)
    action_build_swift_app
    ;;
  --help|-h|help)
    show_usage
    ;;
  *)
    echo "Error: Unknown action '$action'" >&2
    echo "" >&2
    show_usage
    exit 1
    ;;
esac
