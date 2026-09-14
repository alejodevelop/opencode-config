#!/usr/bin/env sh
set -eu

target="."
target_set="0"
start_marker="<!-- opencode-memory-kit:start -->"
end_marker="<!-- opencode-memory-kit:end -->"
tmp_file=""

cleanup() {
  if [ -n "$tmp_file" ]; then
    rm -f -- "$tmp_file"
  fi
}

trap cleanup 0
trap 'exit 1' HUP INT TERM

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      printf '%s\n' "Warning: --force is deprecated and ignored for docs/ai-memory; existing memory files are never overwritten." >&2
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/bootstrap-project.sh [target-dir] [--force]"
      exit 0
      ;;
    --)
      shift
      if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$target_set" -eq 1 ]; }; then
        printf '%s\n' "Only one target directory may be specified." >&2
        exit 2
      fi
      if [ "$#" -eq 1 ]; then
        target="$1"
        target_set="1"
      fi
      break
      ;;
    -*)
      printf '%s\n' "Unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [ "$target_set" -eq 1 ]; then
        printf '%s\n' "Only one target directory may be specified." >&2
        exit 2
      fi
      target="$1"
      target_set="1"
      ;;
  esac
  shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
template_root="$repo_root/templates/project"
docs_template_root="$template_root/docs"
managed_agents_template="$template_root/AGENTS.memory.md"

create_agents_file() {
  file_path="$1"
  {
    printf '%s\n\n' "# Project Instructions"
    cat "$managed_agents_template"
  } > "$file_path"
  printf '%s\n' "Created AGENTS.md"
}

sync_agents_file() {
  file_path="$1"
  use_crlf="0"
  cr=$(printf '\r')

  if grep -q "$cr" "$file_path"; then
    use_crlf="1"
  fi

  start_count=$(awk -v marker="$start_marker" '{ line = $0; while ((at = index(line, marker)) > 0) { count++; line = substr(line, at + length(marker)) } } END { print count + 0 }' "$file_path")
  end_count=$(awk -v marker="$end_marker" '{ line = $0; while ((at = index(line, marker)) > 0) { count++; line = substr(line, at + length(marker)) } } END { print count + 0 }' "$file_path")
  start_line_count=$(awk -v marker="$start_marker" '{ sub(/\r$/, "", $0); if ($0 == marker) count++ } END { print count + 0 }' "$file_path")
  end_line_count=$(awk -v marker="$end_marker" '{ sub(/\r$/, "", $0); if ($0 == marker) count++ } END { print count + 0 }' "$file_path")

  if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    sync_mode="append"
  elif [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ] && [ "$start_line_count" -eq 1 ] && [ "$end_line_count" -eq 1 ]; then
    start_line=$(awk -v marker="$start_marker" '{ sub(/\r$/, "", $0); if ($0 == marker) { print NR; exit } }' "$file_path")
    end_line=$(awk -v marker="$end_marker" '{ sub(/\r$/, "", $0); if ($0 == marker) { print NR; exit } }' "$file_path")

    if [ "$start_line" -ge "$end_line" ]; then
      printf '%s\n' "Invalid AGENTS.md markers in $file_path. Fix the marker order manually." >&2
      exit 1
    fi

    sync_mode="replace"
  else
    printf '%s\n' "Invalid AGENTS.md markers in $file_path. Expected exactly one managed block or none." >&2
    exit 1
  fi

  file_dir=$(dirname "$file_path")
  tmp_file=$(mktemp "$file_dir/.AGENTS.md.tmp.XXXXXX")
  cp -p -- "$file_path" "$tmp_file"

  write_replacement() {
    awk -v use_crlf="$use_crlf" '
      BEGIN { ORS = (use_crlf == "1") ? "\r\n" : "\n" }
      { sub(/\r$/, "", $0); print $0 }
    ' "$managed_agents_template"
  }

  if [ "$sync_mode" = "replace" ]; then
    : > "$tmp_file"
    if [ "$start_line" -gt 1 ]; then
      head -n "$((start_line - 1))" "$file_path" >> "$tmp_file"
    fi
    write_replacement >> "$tmp_file"
    tail -n "+$((end_line + 1))" "$file_path" >> "$tmp_file"
  else
    cat "$file_path" > "$tmp_file"
    if [ -s "$file_path" ]; then
      last_byte=$(tail -c 1 "$file_path" | od -An -tu1 | tr -d ' ')
      if [ "$use_crlf" = "1" ]; then
        newline=$(printf '\r\nX')
        newline=${newline%X}
      else
        newline=$(printf '\nX')
        newline=${newline%X}
      fi
      if [ "$last_byte" = "10" ]; then
        printf '%s' "$newline" >> "$tmp_file"
      else
        printf '%s%s' "$newline" "$newline" >> "$tmp_file"
      fi
    fi
    write_replacement >> "$tmp_file"
  fi

  if cmp -s "$file_path" "$tmp_file"; then
    rm -f "$tmp_file"
    tmp_file=""
    printf '%s\n' "AGENTS.md already up to date"
    return
  fi

  mv "$tmp_file" "$file_path"
  tmp_file=""

  if [ "$sync_mode" = "replace" ]; then
    printf '%s\n' "Updated AGENTS.md (refreshed managed memory workflow block)"
  else
    printf '%s\n' "Updated AGENTS.md (appended memory workflow block)"
  fi
}

if [ ! -d "$target" ]; then
  printf '%s\n' "Target directory does not exist: $target" >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
target_agents="$target/AGENTS.md"

if [ -f "$target_agents" ]; then
  sync_agents_file "$target_agents"
else
  create_agents_file "$target_agents"
fi

find "$docs_template_root" -type f | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$template_root/"}
  destination="$target/$relative_path"
  destination_dir=$(dirname "$destination")

  mkdir -p "$destination_dir"

  if [ -f "$destination" ]; then
    printf '%s\n' "Skipped $relative_path"
    continue
  fi

  cp "$source_path" "$destination"
  printf '%s\n' "Created $relative_path"
done

printf '\n'
printf '%s\n' "Project memory workflow is ready in $target"
printf '%s\n' "Next steps:"
printf '%s\n' "  1. Open the project in OpenCode"
printf '%s\n' "  2. Work as usual with plan and build"
printf '%s\n' "  3. Let OpenCode delegate broad reading to explore and multi-step execution to general"
printf '%s\n' "  4. Run /sync-memory [scope] after accepted work when durable repo truth changed"
printf '%s\n' "  5. If the repo uses OpenSpec or another spec workflow, run /sync-memory [scope] after each spec archive for accepted work or say no durable memory update is needed"
printf '%s\n' "  6. Run /recall-feature <query> in future sessions"
printf '%s\n' "  7. Use /remember-feature <slug> to force a focused feature-note refresh"
printf '%s\n' "  8. Use /review-memory [scope] to force a broader stale-memory review"
printf '%s\n' "You can rerun this same bootstrap command later to refresh managed AGENTS.md instructions."
printf '%s\n' "Existing notes under docs/ai-memory/ are never overwritten; --force is deprecated for memory files."
