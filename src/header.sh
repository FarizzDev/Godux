# Header
echo -e "\e[38;2;72;118;255m"
cat <<"EOF"
           ____  ___  ____  _   ___  __
          / ___|/ _ \|  _ \| | | \ \/ /
         | |  _| | | | | | | | | |\  /
         | |_| | |_| | |_| | |_| |/  \
          \____|\___/|____/ \___//_/\_\
EOF
echo -e "\e[0m"
echo -e "             \e[38;2;255;255;255mGodot Universal eXport\e[0m"
echo ""
echo -e "\e[38;2;255;255;0m Export Godot Projects From Anywhere, To Anywhere.\e[0m"
echo -e "\e[38;2;72;118;255m====================================================\e[0m"

if [[ ! -e "export_presets.cfg" ]]; then
  printf "\n\e[1;31m[ERROR]\e[0m Can't find export_presets.cfg. Exiting.\n"
  exit 1
fi
