printf "\n"
if [ -z "$(git config --get-all user.name)" ]; then
  read -p "Git username: " name
  git config --global user.name "$name"
fi
if [ -z "$(git config --get-all user.email)" ]; then
  read -p "Git email: " email
  git config --global user.email "$email"
fi

GITHUB_USERNAME="$(gh api user --jq .login)"
if [[ -z "$GITHUB_USERNAME" ]]; then
  echo -e "${ERROR} Failed to get GitHub username. Please check your authentication."
  exit 1
else
  echo -e "${INFO} Authenticated as $GITHUB_USERNAME"
fi

CWD=$(readlink -f .)
if ! git config --get-all safe.directory | grep -q "^$CWD"; then
  git config --global --add safe.directory "$CWD"
fi
if [ ! -d "$CWD/.git" ]; then
  read -p "Enter the name for the new repository: " REPO_NAME
  printf "\n"
  echo "Creating new repository..."
  gh repo create "$REPO_NAME" --private
  git init
  git branch -M main
  git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
  REPO_NAME=$(basename -s .git "$(git remote get-url origin)")
fi
