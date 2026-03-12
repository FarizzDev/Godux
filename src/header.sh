# Header
TAGLINE="Crack The Limit and Go Beyond It."
TOTAL_WIDTH=52
TAGLINE_LEN=${#TAGLINE}
PADDING=$(((TOTAL_WIDTH - TAGLINE_LEN) / 2))
echo -e "\e[38;2;72;118;255m"

cat <<"EOF"
           ____  ___  ____  _   ___  __
          / ___|/ _ \|  _ \| | | \ \/ /
         | |  _| | | | | | | | | |\  /
         | |_| | |_| | |_| | |_| |/  \
          \____|\___/|____/ \___//_/\_\
EOF
echo -e "\e[0m"
echo -e "              \e[38;2;255;255;255mGodot Universal Export\e[0m"
echo ""
printf "%${PADDING}s" ""
echo -e "\e[38;2;255;255;0m${TAGLINE}\e[0m"
echo -e "\e[38;2;72;118;255m====================================================\e[0m"

if [[ ! -e "export_presets.cfg" ]]; then
  printf "\n\e[1;31m[ERROR]\e[0m Can't find export_presets.cfg. Exiting.\n"
  exit 1
fi
