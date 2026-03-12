#!/bin/bash

expand_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found!" >&2
    return
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*(source|\.)[[:space:]]+(.+) ]]; then

      local target="${BASH_REMATCH[2]}"

      target="${target%\"}"
      target="${target#\"}"
      target="${target%\'}"
      target="${target#\'}"

      target="${target%% \#*}"

      expand_file "$target"
    else
      printf "%s\n" "$line"
    fi
  done <"$file"
}

expand_file ./main.sh
