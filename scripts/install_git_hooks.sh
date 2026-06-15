#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook_dir="$repo_root/.git/hooks"
hook_path="$hook_dir/pre-commit"
tmp_hook="$(mktemp)"

cat >"$tmp_hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

exec make check
EOF

install -d "$hook_dir"
install -m 755 "$tmp_hook" "$hook_path"
rm -f "$tmp_hook"

printf 'Installed pre-commit hook at %s\n' "$hook_path"
