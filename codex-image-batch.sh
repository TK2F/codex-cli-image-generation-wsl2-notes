#!/usr/bin/env bash
set -euo pipefail

UI_MODE="auto"
SPEC_PATH=""
OUTPUT_ROOT=""
CODEX_BIN="${CODEX_BIN:-}"
MANUAL=0
PREVIEW=0
NO_PROMPT=0
DOCTOR=0
LIST_PRESETS=0
STOP_ON_JOB_ERROR=0
OVERWRITE=0
PAUSE_AT_END=0
INTER_JOB_DELAY_SECONDS=2
GENERATED_IMAGE_WAIT_SECONDS=5
RETRY_COUNT=1
RETRY_DELAY_SECONDS=3
CODEX_CMD=()

declare -A ASPECT_PROMPT_JA=(
  [square]="正方形 1:1、目標サイズは 1024x1024。"
  [portrait]="縦長画像、目標サイズは 1024x1536。"
  [landscape]="横長画像、目標サイズは 1536x1024。"
  [instagram_story]="Instagram Story 向けの縦長画像。希望比率は 9:16。実運用では 1024x1536 に寄る想定で扱ってください。"
  [instagram_post]="Instagram フィード向けの縦長画像。希望比率は 4:5。実運用では 1024x1536 に寄る可能性があります。"
  [hero_banner]="ヒーローバナー向けの横長画像。希望比率は 16:9。実運用では 1536x1024 に寄る想定で扱ってください。"
)

declare -A ASPECT_PROMPT_EN=(
  [square]="Square 1:1, target size 1024x1024."
  [portrait]="Portrait image, target size 1024x1536."
  [landscape]="Landscape image, target size 1536x1024."
  [instagram_story]="Vertical Instagram Story style image. Desired ratio is 9:16. In practice, expect the tool to map this to 1024x1536."
  [instagram_post]="Portrait Instagram feed image. Desired ratio is 4:5. In practice, the tool may map this to 1024x1536."
  [hero_banner]="Wide hero-banner image. Desired ratio is 16:9. In practice, expect the tool to map this to 1536x1024."
)

declare -A ASPECT_LABELS=(
  [square]="square (1024x1024)"
  [portrait]="portrait (1024x1536)"
  [landscape]="landscape (1536x1024)"
  [instagram_story]="instagram_story (9:16 practical portrait)"
  [instagram_post]="instagram_post (4:5 practical portrait)"
  [hero_banner]="hero_banner (16:9 practical landscape)"
)

declare -A STYLE_PROMPT_JA=(
  [none]=""
  [watercolor]="水彩風で、にじみと紙の質感を感じる表現。"
  [cinematic]="映画的で奥行きがあり、光と空気感の演出が強い表現。"
  [pixel_art]="高密度で読みやすいピクセルアート。"
  [product_render]="清潔で上品な商品ビジュアル寄りの表現。"
)

declare -A STYLE_PROMPT_EN=(
  [none]=""
  [watercolor]="Watercolor style with soft bleeding edges and paper texture."
  [cinematic]="Cinematic look with depth, atmosphere, and dramatic lighting."
  [pixel_art]="High-detail, readable pixel art."
  [product_render]="Clean, premium product-render style."
)

info() {
  printf '[info] %s\n' "$*"
}

warn() {
  printf '[warn] %s\n' "$*" >&2
}

err() {
  printf '[error] %s\n' "$*" >&2
}

print_presets() {
  printf 'Aspect presets\n'
  printf '  square           1024x1024\n'
  printf '  portrait         1024x1536\n'
  printf '  landscape        1536x1024\n'
  printf '  instagram_story  practical portrait mapping\n'
  printf '  instagram_post   practical portrait mapping\n'
  printf '  hero_banner      practical landscape mapping\n'
  printf '  custom           WIDTHxHEIGHT, for example 1408x768\n'
  printf '\nStyle presets\n'
  printf '  none\n'
  printf '  watercolor\n'
  printf '  cinematic\n'
  printf '  pixel_art\n'
  printf '  product_render\n'
}

strip_wrapping_quotes() {
  local value="$1"
  if [[ ${#value} -ge 2 ]]; then
    if [[ "${value:0:1}" == '"' && "${value: -1}" == '"' ]]; then
      printf '%s\n' "${value:1:${#value}-2}"
      return 0
    fi
    if [[ "${value:0:1}" == "'" && "${value: -1}" == "'" ]]; then
      printf '%s\n' "${value:1:${#value}-2}"
      return 0
    fi
  fi
  printf '%s\n' "$value"
}

normalize_input_path() {
  local raw_value="${1:-}"
  raw_value="$(strip_wrapping_quotes "$raw_value")"

  if [[ -z "$raw_value" ]]; then
    printf '\n'
    return 0
  fi

  local converted="$raw_value"
  local drive remainder without_prefix

  case "$converted" in
    \\\\wsl.localhost\\*|\\\\wsl\$\\*)
      without_prefix="${converted#\\\\wsl.localhost\\}"
      if [[ "$without_prefix" == "$converted" ]]; then
        without_prefix="${converted#\\\\wsl\$\\}"
      fi
      without_prefix="${without_prefix#*\\}"
      without_prefix="${without_prefix//\\//}"
      printf '/%s\n' "$without_prefix"
      return 0
      ;;
  esac

  if [[ "$converted" =~ ^([A-Za-z]):[\\/](.*)$ ]]; then
    drive="${BASH_REMATCH[1],,}"
    remainder="${BASH_REMATCH[2]}"
    remainder="${remainder//\\//}"
    printf '/mnt/%s/%s\n' "$drive" "$remainder"
    return 0
  fi

  printf '%s\n' "$converted"
}

resolve_path() {
  local raw_path="${1:-}"
  local base_dir="${2:-$PWD}"
  local normalized_path

  normalized_path="$(normalize_input_path "$raw_path")"
  if [[ -z "$normalized_path" ]]; then
    printf '\n'
    return 0
  fi

  if [[ "$normalized_path" = ~* ]]; then
    normalized_path="${normalized_path/#\~/$HOME}"
  fi

  if [[ "$normalized_path" = /* ]]; then
    realpath -m "$normalized_path"
  else
    realpath -m "$base_dir/$normalized_path"
  fi
}

display_path() {
  local raw_path="${1:-}"
  local normalized
  normalized="$(realpath -m "$raw_path")"
  if [[ "$normalized" == "$PWD"* ]]; then
    realpath --relative-to="$PWD" "$normalized"
  else
    printf '%s\n' "$normalized"
  fi
}

usage() {
  cat <<'EOF'
Usage: codex-image-batch.sh [options]

Options:
  --spec PATH                  JSON spec path
  --output-root PATH           Override output root
  --codex-bin PATH             Explicit codex executable path (or set CODEX_BIN)
  --ui-mode auto|cli           Input mode selector (default: auto)
  --manual                     Skip JSON and enter one job manually
  --preview                    Print prompts/commands without executing Codex
  --doctor                     Print environment diagnostics and exit
  --list-presets               Print built-in aspect/style presets and exit
  --no-prompt                  Non-interactive mode; require --spec or --manual
  --stop-on-job-error          Stop the batch on first failed job
  --overwrite                  Overwrite existing output files
  --pause-at-end               Wait for Enter before exit
  --inter-job-delay N          Seconds to wait between jobs (default: 2)
  --generated-image-wait N     Seconds to wait for ~/.codex/generated_images fallback (default: 5)
  --retry-count N              Retry count for failed jobs (default: 1)
  --retry-delay N              Seconds between retries (default: 3)
  -h, --help                   Show this help
EOF
}

while (($#)); do
  case "$1" in
    --spec) SPEC_PATH="${2:-}"; shift 2 ;;
    --output-root) OUTPUT_ROOT="${2:-}"; shift 2 ;;
    --codex-bin) CODEX_BIN="${2:-}"; shift 2 ;;
    --ui-mode) UI_MODE="${2:-}"; shift 2 ;;
    --manual) MANUAL=1; shift ;;
    --preview) PREVIEW=1; shift ;;
    --doctor) DOCTOR=1; shift ;;
    --list-presets) LIST_PRESETS=1; shift ;;
    --no-prompt) NO_PROMPT=1; shift ;;
    --stop-on-job-error) STOP_ON_JOB_ERROR=1; shift ;;
    --overwrite) OVERWRITE=1; shift ;;
    --pause-at-end) PAUSE_AT_END=1; shift ;;
    --inter-job-delay) INTER_JOB_DELAY_SECONDS="${2:-}"; shift 2 ;;
    --generated-image-wait) GENERATED_IMAGE_WAIT_SECONDS="${2:-}"; shift 2 ;;
    --retry-count) RETRY_COUNT="${2:-}"; shift 2 ;;
    --retry-delay) RETRY_DELAY_SECONDS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ "$UI_MODE" != "auto" && "$UI_MODE" != "cli" ]]; then
  err "--ui-mode must be auto or cli for this WSL/bash script."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_dependencies() {
  local missing=()
  local dependency
  for dependency in jq python3 realpath find sort awk grep cp; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      missing+=("$dependency")
    fi
  done

  if ((${#missing[@]} > 0)); then
    err "Missing required command(s): ${missing[*]}"
    err "Install the missing dependencies and try again."
    exit 1
  fi
}

print_doctor() {
  local dependency
  local missing=0
  printf 'Codex Image Batch Doctor\n'
  printf 'cwd: %s\n' "$PWD"
  printf 'script_dir: %s\n' "$SCRIPT_DIR"
  printf 'shell: %s\n' "${SHELL:-unknown}"
  printf 'CODEX_BIN env: %s\n' "${CODEX_BIN:-<unset>}"
  printf 'CODEX_HOME env: %s\n' "${CODEX_HOME:-<unset>}"
  printf '\nDependencies\n'
  for dependency in jq python3 realpath find sort awk grep cp; do
    if command -v "$dependency" >/dev/null 2>&1; then
      printf '  ok   %s -> %s\n' "$dependency" "$(command -v "$dependency")"
    else
      printf '  miss %s\n' "$dependency"
      missing=1
    fi
  done

  printf '\nCodex detection\n'
  if command -v codex >/dev/null 2>&1; then
    printf '  PATH codex -> %s\n' "$(command -v codex)"
  else
    printf '  PATH codex -> <not found>\n'
  fi

  local latest_codex=""
  latest_codex="$(ls -1d "$HOME"/.nvm/versions/node/*/bin/codex 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -n "$latest_codex" ]]; then
    printf '  nvm fallback -> %s\n' "$latest_codex"
  else
    printf '  nvm fallback -> <not found>\n'
  fi

  if [[ "$missing" -eq 1 ]]; then
    printf '\nResult: missing dependencies were found.\n'
    return 0
  fi

  ensure_codex
  printf '  selected codex -> %s\n' "$CODEX_BIN"
  printf '  codex version -> '
  "${CODEX_CMD[@]}" --version || true
  printf '\nFeature state\n'
  "${CODEX_CMD[@]}" features list 2>/dev/null | awk '$1=="image_generation" {printf "  image_generation -> %s\n", $NF}'
  printf '\nAdvice\n'
  printf '  Use --preview first if you are not sure the JSON spec is correct.\n'
  printf '  Use relative Linux paths inside WSL, but Windows UNC and drive paths are also accepted.\n'
}

ensure_codex() {
  if [[ -n "$CODEX_BIN" ]]; then
    CODEX_BIN="$(resolve_path "$CODEX_BIN" "$PWD")"
    if [[ ! -x "$CODEX_BIN" ]]; then
      err "The codex executable is not runnable: $CODEX_BIN"
      exit 1
    fi
  elif command -v codex >/dev/null 2>&1; then
    CODEX_BIN="$(command -v codex)"
  else
    local latest_codex=""
    latest_codex="$(ls -1d "$HOME"/.nvm/versions/node/*/bin/codex 2>/dev/null | sort -V | tail -n 1 || true)"
    if [[ -n "$latest_codex" ]]; then
      CODEX_BIN="$latest_codex"
    fi
  fi

  if [[ -z "$CODEX_BIN" || ! -x "$CODEX_BIN" ]]; then
    err "The 'codex' command was not found. Put it on PATH, pass --codex-bin, or set CODEX_BIN."
    exit 1
  fi

  export PATH
  PATH="$(dirname "$CODEX_BIN"):$PATH"
  CODEX_CMD=("$CODEX_BIN")
}

choose_mode() {
  if [[ "$MANUAL" -eq 1 ]]; then
    printf 'manual\n'
    return 0
  fi
  if [[ -n "$SPEC_PATH" ]]; then
    printf 'spec\n'
    return 0
  fi
  if [[ "$NO_PROMPT" -eq 1 ]]; then
    err "Either --spec or --manual is required with --no-prompt."
    exit 1
  fi

  printf 'Choose run mode:\n'
  printf '1. JSON batch/spec file\n'
  printf '2. Manual one-off job\n'
  while true; do
    read -r -p "Enter number: " response
    case "$response" in
      1) printf 'spec\n'; return 0 ;;
      2) printf 'manual\n'; return 0 ;;
      *) warn "Please enter 1 or 2." ;;
    esac
  done
}

confirm_execution() {
  local mode_label="$1"
  if [[ "$NO_PROMPT" -eq 1 || "$PREVIEW" -eq 1 ]]; then
    return 0
  fi

  printf '\nAbout to run %s.\n' "$mode_label"
  printf 'Tip: use --preview first if you only want to inspect prompts.\n'
  while true; do
    read -r -p "Continue? (yes/no): " response
    case "$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')" in
      yes|y) return 0 ;;
      no|n)
        info "Cancelled before execution."
        exit 0
        ;;
      *) warn "Please answer yes or no." ;;
    esac
  done
}

select_spec_path() {
  if [[ -n "$SPEC_PATH" ]]; then
    local resolved_spec
    resolved_spec="$(resolve_path "$SPEC_PATH" "$PWD")"
    if [[ ! -f "$resolved_spec" ]]; then
      err "Spec file not found: $SPEC_PATH"
      exit 1
    fi
    printf '%s\n' "$resolved_spec"
    return 0
  fi

  while true; do
    local resolved_candidate
    read -r -p "Enter the path to a JSON spec file: " candidate
    if [[ -z "$candidate" ]]; then
      err "No JSON file selected."
      exit 1
    fi
    resolved_candidate="$(resolve_path "$candidate" "$PWD")"
    if [[ -d "$resolved_candidate" ]]; then
      warn "That path is a directory. Enter a JSON file path, not a folder."
      continue
    fi
    if [[ -f "$resolved_candidate" ]]; then
      if [[ "${resolved_candidate,,}" != *.json ]]; then
        warn "The selected file does not end with .json. Continuing anyway."
      fi
      printf '%s\n' "$resolved_candidate"
      return 0
    fi
    warn "File not found: $resolved_candidate"
  done
}

read_choice() {
  local prompt="$1"
  local default_value="$2"
  shift 2
  local allowed=("$@")
  local response lower

  while true; do
    if [[ -n "$default_value" ]]; then
      read -r -p "$prompt [$default_value]: " response
      [[ -z "$response" ]] && response="$default_value"
    else
      read -r -p "$prompt: " response
    fi

    lower="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"
    for allowed_value in "${allowed[@]}"; do
      if [[ "$lower" == "$allowed_value" ]]; then
        printf '%s\n' "$allowed_value"
        return 0
      fi
    done
    warn "Allowed values: ${allowed[*]}"
  done
}

read_existing_path() {
  local prompt="$1"
  local base_dir="$2"
  local required="${3:-1}"
  local candidate resolved

  while true; do
    read -r -p "$prompt: " candidate
    if [[ -z "$candidate" ]]; then
      if [[ "$required" -eq 1 ]]; then
        warn "A path is required."
        continue
      fi
      printf '\n'
      return 0
    fi
    resolved="$(resolve_path "$candidate" "$base_dir")"
    if [[ -e "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
    warn "Path not found: $resolved"
  done
}

read_multiline_input() {
  local prompt="$1"
  local required="${2:-1}"
  local tmp="$TMP_DIR/multiline-$$.txt"

  while true; do
    : >"$tmp"
    printf '%s\n' "$prompt"
    printf 'Finish by entering a single line with `.done`.\n'
    while IFS= read -r line; do
      [[ "$line" == ".done" ]] && break
      printf '%s\n' "$line" >>"$tmp"
    done

    if [[ "$required" -eq 0 ]] || [[ -s "$tmp" ]]; then
      cat "$tmp"
      return 0
    fi
    warn "Prompt cannot be empty."
  done
}

select_aspect_ratio() {
  local keys=(square portrait landscape instagram_story instagram_post hero_banner custom)
  local choice

  printf 'Choose aspect ratio:\n'
  local idx=1
  for key in "${keys[@]}"; do
    if [[ "$key" == "custom" ]]; then
      printf '%d. custom WIDTHxHEIGHT\n' "$idx"
    else
      printf '%d. %s\n' "$idx" "${ASPECT_LABELS[$key]}"
    fi
    ((idx++))
  done

  while true; do
    read -r -p "Enter number: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#keys[@]} )); then
      local selected="${keys[$((choice-1))]}"
      if [[ "$selected" == "custom" ]]; then
        while true; do
          read -r -p "Enter custom size like 1024x1024: " custom_size
          if [[ "$custom_size" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]]; then
            printf '%s\n' "$custom_size"
            return 0
          fi
          warn "Custom size must look like 1024x1024."
        done
      fi
      printf '%s\n' "$selected"
      return 0
    fi
    warn "Please enter a valid number."
  done
}

prompt_manual_job() {
  local base_dir="$1"
  local language mode name aspect model constraints style_preset style_custom input_image add_reference reference_image prompt

  info "Manual job mode"
  language="$(read_choice "Language (ja/en)" "ja" ja en)"
  mode="$(read_choice "Mode (generate/edit)" "generate" generate edit)"
  read -r -p "Output file name without extension (default: output): " name
  aspect="$(select_aspect_ratio)"
  read -r -p "Codex model override, or press Enter to keep default: " model
  read -r -p "Extra constraints, or press Enter to use the default no-text/no-logo/no-watermark rule: " constraints
  style_preset="$(read_choice "Style preset (none/watercolor/cinematic/pixel_art/product_render)" "none" none watercolor cinematic pixel_art product_render)"
  read -r -p "Custom style note, or press Enter to skip: " style_custom

  if [[ "$mode" == "edit" ]]; then
    input_image="$(read_existing_path "Path to the base image" "$base_dir" 1)"
    add_reference="$(read_choice "Add a second reference image? (yes/no)" "no" yes no)"
    if [[ "$add_reference" == "yes" ]]; then
      reference_image="$(read_existing_path "Path to the reference image" "$base_dir" 1)"
    else
      reference_image=""
    fi
    prompt="$(read_multiline_input "Enter the edit instructions in Japanese or English" 1)"
  else
    reference_image=""
    prompt="$(read_multiline_input "Enter the generation prompt in Japanese or English" 1)"
  fi

  python3 - <<'PY' "$name" "$mode" "$language" "$aspect" "$model" "$constraints" "$style_preset" "$style_custom" "$input_image" "$reference_image" "$prompt"
import json, sys
name, mode, language, aspect, model, constraints, style_preset, style_custom, input_image, reference_image, prompt = sys.argv[1:]
job = {
    "name": name,
    "mode": mode,
    "language": language,
    "aspect_ratio": aspect,
    "style_preset": style_preset,
    "prompt": prompt,
}
if model:
    job["codex_model"] = model
if constraints:
    job["constraints"] = constraints
if style_custom:
    job["style_custom"] = style_custom
if input_image:
    job["input_image"] = input_image
if reference_image:
    job["input_images"] = [reference_image]
print(json.dumps(job, ensure_ascii=False))
PY
}

normalize_jobs() {
  local spec_file="$1"
  python3 - <<'PY' "$spec_file"
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    doc = json.loads(path.read_text(encoding="utf-8"))
except UnicodeDecodeError as exc:
    raise SystemExit(f"Could not read JSON as UTF-8: {exc}") from exc
except json.JSONDecodeError as exc:
    raise SystemExit(f"Invalid JSON in {path}: line {exc.lineno}, column {exc.colno}: {exc.msg}") from exc

if isinstance(doc, list):
    jobs = doc
elif isinstance(doc, dict) and "jobs" in doc:
    defaults = doc.get("defaults") or {}
    jobs = []
    for job in doc["jobs"]:
        merged = dict(defaults)
        merged.update(job)
        jobs.append(merged)
elif isinstance(doc, dict):
    jobs = [doc]
else:
    raise SystemExit("JSON root must be an object, an array, or an object containing jobs.")

for job in jobs:
    print(json.dumps(job, ensure_ascii=False))
PY
}

get_default_output_root_from_spec() {
  local spec_file="$1"
  python3 - <<'PY' "$spec_file"
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
doc = json.loads(path.read_text(encoding="utf-8"))
if isinstance(doc, dict):
    defaults = doc.get("defaults") or {}
    value = defaults.get("output_dir", "")
    if value:
        print(value)
PY
}

is_image_feature_enabled() {
  if "${CODEX_CMD[@]}" features list 2>/dev/null | awk '$1=="image_generation" {print $NF}' | grep -qx 'true'; then
    return 0
  fi
  return 1
}

sanitize_filename() {
  local name="${1:-}"
  local fallback="${2:-output}"
  local candidate="$name"
  [[ -z "$candidate" ]] && candidate="$fallback"
  [[ -z "$candidate" ]] && candidate="output"
  candidate="${candidate//\//_}"
  candidate="${candidate//\\/_}"
  candidate="${candidate//:/_}"
  candidate="${candidate//\*/_}"
  candidate="${candidate//\?/_}"
  candidate="${candidate//\"/_}"
  candidate="${candidate//</_}"
  candidate="${candidate//>/_}"
  candidate="${candidate//|/_}"
  if [[ "${candidate,,}" != *.png ]]; then
    candidate="${candidate}.png"
  fi
  printf '%s\n' "$candidate"
}

get_aspect_prompt() {
  local key="${1:-square}"
  local language="${2:-ja}"

  if [[ "$key" =~ ^[0-9]{3,4}x[0-9]{3,4}$ ]]; then
    if [[ "$language" == "ja" ]]; then
      printf '目標サイズは %s です。\n' "$key"
    else
      printf 'Target size is %s.\n' "$key"
    fi
    return 0
  fi

  if [[ "$language" == "ja" ]]; then
    printf '%s\n' "${ASPECT_PROMPT_JA[$key]:-}"
  else
    printf '%s\n' "${ASPECT_PROMPT_EN[$key]:-}"
  fi
}

get_style_prompt() {
  local key="${1:-none}"
  local language="${2:-ja}"
  if [[ "$language" == "ja" ]]; then
    printf '%s\n' "${STYLE_PROMPT_JA[$key]:-}"
  else
    printf '%s\n' "${STYLE_PROMPT_EN[$key]:-}"
  fi
}

build_prompt() {
  local job_json="$1"
  local output_file_name="$2"

  python3 - <<'PY' "$job_json" "$output_file_name"
import json, sys
job = json.loads(sys.argv[1])
output = sys.argv[2]
language = (job.get("language") or "ja").strip().lower()
mode = (job.get("mode") or "generate").strip().lower()
prompt_override = (job.get("prompt") or "").strip()
subject = (job.get("subject") or "").strip()
scene = (job.get("scene") or "").strip()
style_custom = (job.get("style_custom") or "").strip()
constraints = (job.get("constraints") or "").strip()
aspect = (job.get("aspect_prompt") or "").strip()
style = (job.get("style_prompt") or "").strip()

if not prompt_override and not subject:
    raise SystemExit("Either prompt or subject is required.")

if language == "ja":
    parts = [
        "built-in の画像生成機能だけを使ってください。",
        "プログラムで描いたり、SVG や HTML や canvas で代用したりしないでください。",
        aspect,
        "添付画像を編集してください。" if mode == "edit" else "新規に画像を生成してください。",
    ]
    if prompt_override:
        parts.append(prompt_override)
    else:
        parts.append(subject)
        if scene:
            parts.append(scene)
        if style:
            parts.append(style)
        if style_custom:
            parts.append(style_custom)
    parts.append(constraints or "文字、ロゴ、透かしは入れないでください。")
    parts.append(f"最終画像を現在のディレクトリに {output} としてコピーし、出力パスを明示してください。")
else:
    parts = [
        "Use the built-in image generation capability only.",
        "Do not create the image programmatically or substitute SVG, HTML, or canvas output.",
        aspect,
        "Edit the attached image." if mode == "edit" else "Generate a new image.",
    ]
    if prompt_override:
        parts.append(prompt_override)
    else:
        parts.append(subject)
        if scene:
            parts.append(scene)
        if style:
            parts.append(style)
        if style_custom:
            parts.append(style_custom)
    parts.append(constraints or "No text, no logo, no watermark.")
    parts.append(f"Copy the final image into the current directory as {output} and explicitly state the output path.")

print(" ".join(part for part in parts if part))
PY
}

summary_file="$TMP_DIR/summary.ndjson"
: >"$summary_file"

append_summary() {
  printf '%s\n' "$1" >>"$summary_file"
}

run_job() {
  local job_json="$1"
  local spec_dir="$2"
  local default_output_root="$3"
  local image_feature_enabled="$4"

  local name mode language aspect style_preset codex_model output_dir output_file_name output_file_path job_output_dir
  local prompt constraints style_prompt aspect_prompt
  local display_output_path display_log_path
  local raw_log_path marker_file run_output attempt exit_code success generated copied_from_generated status message attempts
  local -a input_images codex_args

  name="$(jq -r '.name // "unnamed-job"' <<<"$job_json")"
  mode="$(jq -r '.mode // "generate"' <<<"$job_json" | tr '[:upper:]' '[:lower:]')"
  language="$(jq -r '.language // "ja"' <<<"$job_json" | tr '[:upper:]' '[:lower:]')"
  aspect="$(jq -r '.aspect_ratio // "square"' <<<"$job_json")"
  style_preset="$(jq -r '.style_preset // "none"' <<<"$job_json")"
  codex_model="$(jq -r '.codex_model // empty' <<<"$job_json")"
  constraints="$(jq -r '.constraints // empty' <<<"$job_json")"
  output_dir="$(jq -r '.output_dir // empty' <<<"$job_json")"

  job_output_dir="$default_output_root"
  if [[ -n "$output_dir" ]]; then
    job_output_dir="$(resolve_path "$output_dir" "$spec_dir")"
  fi
  mkdir -p "$job_output_dir"

  output_file_name="$(sanitize_filename "$(jq -r '.output_file // empty' <<<"$job_json")" "$name")"
  output_file_path="$job_output_dir/$output_file_name"
  raw_log_path="$job_output_dir/${output_file_name%.png}.codex.log.txt"
  display_output_path="$(display_path "$output_file_path")"
  display_log_path="$(display_path "$raw_log_path")"

  input_images=()
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    resolved_item="$(resolve_path "$item" "$spec_dir")"
    if [[ ! -e "$resolved_item" ]]; then
      append_summary "$(jq -nc --arg name "$name" --arg status "failed" --arg output "$display_output_path" --arg message "Input image not found: $resolved_item" --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,attempts:0,raw_log_path:$log}')"
      err "$name: Input image not found: $resolved_item"
      return 1
    fi
    input_images+=("$resolved_item")
  done < <(jq -r '[(.input_image // empty)] + (.input_images // []) | .[]' <<<"$job_json")

  if [[ "$mode" == "edit" && "${#input_images[@]}" -eq 0 ]]; then
    append_summary "$(jq -nc --arg name "$name" --arg status "failed" --arg output "$display_output_path" --arg message "Edit mode requires at least one input image." --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,attempts:0,raw_log_path:$log}')"
    err "$name: Edit mode requires at least one input image."
    return 1
  fi

  aspect_prompt="$(get_aspect_prompt "$aspect" "$language")"
  if [[ -z "$aspect_prompt" ]]; then
    append_summary "$(jq -nc --arg name "$name" --arg status "failed" --arg output "$display_output_path" --arg message "Unknown aspect ratio preset: $aspect" --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,attempts:0,raw_log_path:$log}')"
    err "$name: Unknown aspect ratio preset: $aspect"
    return 1
  fi

  style_prompt="$(get_style_prompt "$style_preset" "$language")"
  if [[ -z "$style_prompt" && "$style_preset" != "none" ]]; then
    append_summary "$(jq -nc --arg name "$name" --arg status "failed" --arg output "$display_output_path" --arg message "Unknown style preset: $style_preset" --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,attempts:0,raw_log_path:$log}')"
    err "$name: Unknown style preset: $style_preset"
    return 1
  fi

  prompt="$(build_prompt "$(jq -c --arg aspect_prompt "$aspect_prompt" --arg style_prompt "$style_prompt" '. + {aspect_prompt:$aspect_prompt, style_prompt:$style_prompt}' <<<"$job_json")" "$output_file_name")"

  if [[ "$PREVIEW" -eq 1 ]]; then
    info "$name: preview ready"
    printf '\n[%s] Prompt\n%s\n\n' "$name" "$prompt"
    codex_args=(exec --skip-git-repo-check)
    [[ "$image_feature_enabled" -eq 0 ]] && codex_args+=(--enable image_generation)
    [[ -n "$codex_model" ]] && codex_args+=(--model "$codex_model")
    for input_image in "${input_images[@]}"; do
      codex_args+=(-i "$input_image")
    done
    codex_args+=(-)
    printf '[%s] Command\n%s %s\n\n' "$name" "$(printf '%q' "${CODEX_CMD[0]}")" "$(printf '%q ' "${codex_args[@]}")"
    append_summary "$(jq -nc --arg name "$name" --arg status "preview" --arg output "$display_output_path" --arg message "Preview only. No command was executed." --arg prompt "$prompt" --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,prompt:$prompt,attempts:0,raw_log_path:$log}')"
    return 0
  fi

  if [[ -f "$output_file_path" && "$OVERWRITE" -ne 1 ]]; then
    append_summary "$(jq -nc --arg name "$name" --arg status "skipped" --arg output "$display_output_path" --arg message "Output file already exists. Use --overwrite to replace it." --arg log "$display_log_path" '{name:$name,status:$status,output_path:$output,message:$message,attempts:0,raw_log_path:$log}')"
    warn "$name: Output file already exists. Use --overwrite to replace it."
    return 0
  fi

  local attempt_summaries=()
  for ((attempt=0; attempt<=RETRY_COUNT; attempt++)); do
    codex_args=(exec --skip-git-repo-check)
    [[ "$image_feature_enabled" -eq 0 ]] && codex_args+=(--enable image_generation)
    [[ -n "$codex_model" ]] && codex_args+=(--model "$codex_model")
    for input_image in "${input_images[@]}"; do
      codex_args+=(-i "$input_image")
    done
    codex_args+=(-)

    marker_file="$TMP_DIR/marker-${name//[^A-Za-z0-9._-]/_}-$attempt"
    : >"$marker_file"
    run_output=""
    if run_output="$(cd "$job_output_dir" && printf '%s\n' "$prompt" | "${CODEX_CMD[@]}" "${codex_args[@]}" 2>&1)"; then
      exit_code=0
    else
      exit_code=$?
    fi
    printf '%s\n' "$run_output" >"$raw_log_path"

    copied_from_generated=0
    if [[ ! -s "$output_file_path" ]]; then
      local deadline=$((SECONDS + GENERATED_IMAGE_WAIT_SECONDS))
      while (( SECONDS <= deadline )); do
        generated="$(find "$(get_generated_images_root)" -type f -newer "$marker_file" -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true)"
        if [[ -n "$generated" && -f "$generated" ]]; then
          cp -f "$generated" "$output_file_path"
          copied_from_generated=1
          break
        fi
        sleep 1
      done
    fi

    if [[ "$exit_code" -eq 0 && -s "$output_file_path" ]]; then
      if [[ "$copied_from_generated" -eq 1 ]]; then
        message="Codex finished and the script recovered the output from ~/.codex/generated_images."
      else
        message="Completed successfully."
      fi
      append_summary "$(jq -nc --arg name "$name" --arg status "success" --arg output "$display_output_path" --arg message "$message" --arg log "$display_log_path" --argjson attempts "$((attempt + 1))" '{name:$name,status:$status,output_path:$output,message:$message,attempts:$attempts,raw_log_path:$log}')"
      info "$name: $message"
      info "Raw log: $display_log_path"
      return 0
    fi

    if [[ "$exit_code" -ne 0 ]]; then
      attempt_summaries+=("attempt $((attempt + 1)): failed with exit code $exit_code")
    else
      attempt_summaries+=("attempt $((attempt + 1)): failed because no output file was found")
    fi

    if (( attempt < RETRY_COUNT )); then
      warn "Retrying $name in $RETRY_DELAY_SECONDS second(s)."
      sleep "$RETRY_DELAY_SECONDS"
    fi
  done

  if [[ "$exit_code" -ne 0 ]]; then
    message="codex exec failed after retry attempts. ${attempt_summaries[*]}"
  else
    message="No output file was found after retry attempts. ${attempt_summaries[*]}"
  fi
  append_summary "$(jq -nc --arg name "$name" --arg status "failed" --arg output "$display_output_path" --arg message "$message" --arg log "$display_log_path" --argjson attempts "$((RETRY_COUNT + 1))" '{name:$name,status:$status,output_path:$output,message:$message,attempts:$attempts,raw_log_path:$log}')"
  err "$name: $message"
  info "Raw log: $display_log_path"
  return 1
}

get_generated_images_root() {
  printf '%s\n' "$(get_codex_home)/generated_images"
}

get_codex_home() {
  if [[ -n "${CODEX_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_HOME"
  else
    printf '%s\n' "$HOME/.codex"
  fi
}

ensure_dependencies
if [[ "$LIST_PRESETS" -eq 1 ]]; then
  print_presets
  exit 0
fi
if [[ "$DOCTOR" -eq 1 ]]; then
  print_doctor
  exit 0
fi
ensure_codex
info "Using codex executable: $CODEX_BIN"
if is_image_feature_enabled; then
  image_feature_enabled=1
  info "Codex image_generation feature is already enabled in config."
else
  image_feature_enabled=0
  warn "Codex image_generation feature is not enabled in config. This script will add --enable image_generation per command."
fi

run_source="$(choose_mode)"
spec_dir="$PWD"

jobs_file="$TMP_DIR/jobs.ndjson"
: >"$jobs_file"

if [[ "$run_source" == "manual" ]]; then
  prompt_manual_job "$spec_dir" >"$jobs_file"
  confirm_execution "a manual one-off image job"
else
  spec_file="$(select_spec_path)"
  spec_dir="$(dirname "$spec_file")"
  normalize_jobs "$spec_file" >"$jobs_file"
  confirm_execution "a JSON batch"
fi

if [[ -n "$OUTPUT_ROOT" ]]; then
  resolved_output_root="$(resolve_path "$OUTPUT_ROOT" "$PWD")"
elif [[ "$run_source" == "spec" ]]; then
  default_output_dir="$(get_default_output_root_from_spec "$spec_file")"
  if [[ -n "$default_output_dir" ]]; then
    resolved_output_root="$(resolve_path "$default_output_dir" "$spec_dir")"
  else
    resolved_output_root="$(realpath -m "$spec_dir/outputs")"
  fi
else
  resolved_output_root="$(realpath -m "$spec_dir/outputs")"
fi

mkdir -p "$resolved_output_root"

job_count="$(wc -l <"$jobs_file" | tr -d ' ')"
if [[ "$job_count" -eq 0 ]]; then
  err "No jobs were found."
  exit 1
fi

completed_count=0
while IFS= read -r job_json; do
  [[ -z "$job_json" ]] && continue
  job_name="$(jq -r '.name // "unnamed-job"' <<<"$job_json")"
  current_index=$((completed_count + 1))
  progress_percent=$((completed_count * 100 / job_count))
  info "Running job $current_index/$job_count: $job_name"
  if run_job "$job_json" "$spec_dir" "$resolved_output_root" "$image_feature_enabled"; then
    :
  else
    if [[ "$STOP_ON_JOB_ERROR" -eq 1 ]]; then
      break
    fi
  fi
  completed_count=$((completed_count + 1))

  if (( completed_count < job_count && INTER_JOB_DELAY_SECONDS > 0 )); then
    for ((remaining=INTER_JOB_DELAY_SECONDS; remaining>=1; remaining--)); do
      info "Waiting $remaining second(s) before next job."
      sleep 1
    done
  fi
done <"$jobs_file"

summary_json="$resolved_output_root/codex-image-batch-run-$(date +%Y%m%d-%H%M%S).json"
jq -s '.' "$summary_file" >"$summary_json"
display_summary_json="$(display_path "$summary_json")"

printf '\nRun summary\n'
jq -r '.[] | [.name, .status, (.attempts|tostring), (.output_path // ""), .message] | @tsv' "$summary_json" |
while IFS=$'\t' read -r name status attempts output_path message; do
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$status" "$attempts" "$output_path" "$message"
done

info "Summary JSON saved to $display_summary_json"

if [[ "$PAUSE_AT_END" -eq 1 ]]; then
  read -r -p "Press Enter to close"
fi
