#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! inventory_output="$(./run-inventory.sh 2>&1)"; then
  printf '%s\n' "$inventory_output"
  exit 1
fi
printf '%s\n' "$inventory_output" | sed -n '1p'

if ! doctor_output="$(.venv/bin/python scripts/ai_doctor.py --inventory 2>&1)"; then
  printf '%s\n' "$doctor_output"
  exit 1
fi
printf '%s\n' "$doctor_output" | sed -n '1p'

.venv/bin/python scripts/check_ai_system.py
