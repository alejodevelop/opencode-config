#!/usr/bin/env sh

target="."
target_set=0
config_dir=${OPENCODE_CONFIG_DIR:-"${HOME}/.config/opencode"}
failures=0

result() {
  printf '%s %s\n' "$1" "$2"
  [ "$1" != FAIL ] || failures=$((failures + 1))
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config-dir)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        result FAIL "missing value for --config-dir"
        exit 1
      fi
      config_dir=$2
      shift
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/doctor.sh [target-dir] [--config-dir DIR]"
      exit 0
      ;;
    -* )
      result FAIL "unknown option: $1"
      exit 1
      ;;
    *)
      if [ "$target_set" -eq 1 ]; then
        result FAIL "only one target directory may be specified"
        exit 1
      fi
      target=$1
      target_set=1
      ;;
  esac
  shift
done

if [ ! -d "$target" ]; then
  result FAIL "target directory missing: $target"
  exit 1
fi
if [ -z "$config_dir" ]; then
  result FAIL "config directory is empty"
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
memory="$target/docs/ai-memory"
if [ -d "$memory" ]; then result PASS "docs/ai-memory exists"; else result FAIL "docs/ai-memory directory missing"; fi
for relative in INDEX.md product-vision.md decisions.md troubleshooting.md features/README.md; do
  if [ -f "$memory/$relative" ]; then result PASS "docs/ai-memory/$relative exists"; else result FAIL "docs/ai-memory/$relative missing"; fi
done

agents="$target/AGENTS.md"
start='<!-- opencode-memory-kit:start -->'
end='<!-- opencode-memory-kit:end -->'
if [ ! -f "$agents" ]; then
  result FAIL "AGENTS.md missing"
else
  marker_data=$(awk -v start="$start" -v end="$end" '
    {
      raw=$0; sub(/\r$/, "", $0)
      line=$0
      while ((at=index(line,start))>0) { sc++; line=substr(line,at+length(start)) }
      line=$0
      while ((at=index(line,end))>0) { ec++; line=substr(line,at+length(end)) }
      if ($0==start) { sl++; sn=NR }
      if ($0==end) { el++; en=NR }
    }
    END { print sc+0, ec+0, sl+0, el+0, sn+0, en+0 }
  ' "$agents")
  set -- $marker_data
  if [ "$1" -eq 1 ] && [ "$2" -eq 1 ] && [ "$3" -eq 1 ] && [ "$4" -eq 1 ] && [ "$5" -lt "$6" ]; then
    result PASS "AGENTS.md markers valid"
  else
    result FAIL "AGENTS.md requires exactly one ordered pair of exclusive marker lines"
  fi
fi

for name in sync-memory remember-feature recall-feature review-memory; do
  if [ -f "$config_dir/commands/$name.md" ]; then result PASS "global command $name exists"; else result FAIL "global command $name missing"; fi
done
for name in memory-curator memory-recall; do
  if [ -f "$config_dir/agents/$name.md" ]; then result PASS "global agent $name exists"; else result FAIL "global agent $name missing"; fi
done

index="$memory/INDEX.md"
indexed_tmp=${TMPDIR:-/tmp}/opencode-memory-kit-doctor.$$.indexed
features_tmp=${TMPDIR:-/tmp}/opencode-memory-kit-doctor.$$.features
trap 'rm -f "$indexed_tmp" "$features_tmp"' 0 HUP INT TERM
: >"$indexed_tmp"
if [ -f "$index" ]; then
  awk '{ line=$0; while (match(line, /features\/[A-Za-z0-9][A-Za-z0-9._-]*\.md/)) { print substr(line,RSTART+9,RLENGTH-9); line=substr(line,RSTART+RLENGTH) } }' "$index" |
    awk '$0 != "README.md" && !seen[$0]++' >"$indexed_tmp"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if [ -f "$memory/features/$name" ]; then result PASS "indexed feature $name exists"; else result FAIL "indexed feature $name missing"; fi
  done <"$indexed_tmp"
fi

: >"$features_tmp"
if [ -d "$memory/features" ]; then
  for path in "$memory/features"/*.md; do
    [ -f "$path" ] || continue
    name=${path##*/}
    [ "$name" = README.md ] && continue
    printf '%s\n' "$name" >>"$features_tmp"
    if ! grep -F -x "$name" "$indexed_tmp" >/dev/null 2>&1; then result FAIL "orphan feature note $name"; fi
    lines=$(awk 'END { print NR+0 }' "$path")
    bytes=$(wc -c <"$path" | tr -d ' ')
    if [ "$lines" -gt 50 ] || [ "$bytes" -gt 8192 ]; then result WARN "feature note $name is large ($lines lines, $bytes bytes)"; fi
  done
fi

if [ "$failures" -eq 0 ]; then result PASS "doctor completed without failures"; fi
[ "$failures" -eq 0 ]
