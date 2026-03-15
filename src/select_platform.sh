# Get all preset names and their platforms
presets_with_platforms=$(perl .github/scripts/lib/parse_presets.pl list)

options=()
options+=("$ALL")

while IFS='|' read -r name platform_type; do
  if [ -z "$name" ] || [ -z "$platform_type" ]; then
    continue
  fi

  case "$platform_type" in
  "Android") color_prefix=$ANDROID ;;
  "iOS") color_prefix=$IOS ;;
  "HTML5") color_prefix=$HTML5 ;;
  "Web") color_prefix=$HTML5 ;;
  "Mac OSX") color_prefix=$MAC_OSX ;;
  "macOS") color_prefix=$MAC_OSX ;;
  "UWP") color_prefix=$UWP ;;
  "Windows Desktop") color_prefix=$WINDOWS ;;
  "Linux/X11") color_prefix=$LINUX ;;
  "Linux") color_prefix=$LINUX ;;
  *) color_prefix="" ;;
  esac
  color_suffix="\e[0m"

  if [ -n "$color_prefix" ]; then
    options+=("$(echo -e "${color_prefix}${name}${color_suffix}")")
  else
    options+=("$name")
  fi
done <<<"$presets_with_platforms"

presetname_raw=$(printf "%b\n" "${options[@]}" | fzf --ansi --no-sort --prompt="Select a preset: ")
preset_name=$(echo "$presetname_raw" | sed -r 's/\x1B\[[0-9;:]*[mK]//g')
platform=$(perl .github/scripts/lib/parse_presets.pl platform "$preset_name")

if [ -z "$preset_name" ]; then
  echo -e "${ERROR} No preset selected. Exiting."
  exit 1
fi

case "$platform" in
"Android") color_prefix=$ANDROID ;;
"iOS") color_prefix=$IOS ;;
"HTML5") color_prefix=$HTML5 ;;
"Web") color_prefix=$HTML5 ;;
"Mac OSX") color_prefix=$MAC_OSX ;;
"macOS") color_prefix=$MAC_OSX ;;
"UWP") color_prefix=$UWP ;;
"Windows Desktop") color_prefix=$WINDOWS ;;
"Linux/X11") color_prefix=$LINUX ;;
"Linux") color_prefix=$LINUX ;;
*) color_prefix="" ;;
esac

echo -e "\n${INFO} Selected preset: ${color_prefix}${preset_name}${RESET}"
