#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Non-interactive installation script for Next.js/React + Tailwind + dev tools
# Usage: sudo install_nextjs_auto.sh \
#            -n my-project-name \
#            -a "Author Name" \
#            [-d /path/to/base-dir]
# -----------------------------------------------------------------------------

# --- Logging ---
LOG_FILE="/var/log/nextjs_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Default Config ---
NODE_MAJOR_MINIMUM=20
BASE_DIR_DEFAULT="$HOME/projects"

# --- Read options ---
PROJECT_NAME=""
AUTHOR_NAME=""
BASE_DIR="$BASE_DIR_DEFAULT"

usage() {
  echo "Usage: sudo $0 -n <project-name> -a \"<Author Name>\" [-d <base-dir>]"
  exit 1
}

while getopts "n:a:d:" opt; do
  case $opt in
    n) PROJECT_NAME="$OPTARG" ;;
    a) AUTHOR_NAME="$OPTARG" ;;
    d) BASE_DIR="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -z "$PROJECT_NAME" || -z "$AUTHOR_NAME" ]] && usage
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"
NEO_USER=${SUDO_USER:-$USER}

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
  echo "🚨 This script must be run with sudo" >&2
  exit 1
fi

# --- Check for apt-get, Git, Curl, jq ---
command -v apt-get &>/dev/null || { echo "apt-get required"; exit 1; }
for pkg in git curl jq; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    apt-get install -y --no-install-recommends "$pkg"
  fi
done

# --- Node.js Functions ---
get_node_major() { command -v node &>/dev/null && node -v | cut -d. -f1 | sed 's/v//' || echo 0; }
install_node() {
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR_MINIMUM}.x | bash - \
    && apt-get install -y nodejs
  echo "Node $(node -v) & npm $(npm -v) installed"
}
ensure_node() {
  local maj=$(get_node_major)
  [[ $maj -lt $NODE_MAJOR_MINIMUM ]] && install_node || echo "Node up to date ($(node -v))"
}

# --- Prepare target directory ---
mkdir -p "$TARGET_DIR"
chown "$NEO_USER:$NEO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

# --- Install Git, Node, npm ---
ensure_node
command -v npm &>/dev/null || apt-get install -y npm

echo "→ create-next-app..."
sudo -H -u "$NEO_USER" bash -lc \
  "cd '$BASE_DIR' && npx create-next-app@latest '$PROJECT_NAME' --use-npm --eslint --no-src-dir --template default"

# --- Dev dependencies ---
echo "→ npm install dev deps..."
sudo -H -u "$NEO_USER" bash -lc \
  "cd '$TARGET_DIR' && npm install -D tailwindcss postcss autoprefixer prettier eslint-config-prettier eslint-plugin-prettier husky lint-staged"

# --- Initialize Tailwind CSS ---
echo "→ Initializing Tailwind CSS (tailwind.config.js & postcss.config.js)"
# Use npx to init, without checking local binaries
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npx tailwindcss@latest init -p\""

# Recreate Tailwind/PostCSS config files
cat > "$TARGET_DIR/tailwind.config.js" << 'EOF'
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

cat > "$TARGET_DIR/postcss.config.js" << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# --- Configure Prettier & lint-staged ---
cat > "$TARGET_DIR/.prettierrc" << 'EOF'
{ "semi":true, "singleQuote":true, "printWidth":80, "tabWidth":2, "trailingComma":"es5" }
EOF
cat > "$TARGET_DIR/.lintstagedrc" << 'EOF'
{ "*.{js,jsx,ts,tsx}":["eslint --fix","prettier --write"],"*.{css,scss,md}":["prettier --write"] }
EOF

# --- Husky pre-commit ---
sudo -H -u "$NEO_USER" bash -lc "cd '$TARGET_DIR' && npx husky install && npx husky add .husky/pre-commit \"npx lint-staged\""

# --- LICENSE ---
year=$(date +%Y)
cat > "$TARGET_DIR/LICENSE" << EOF
MIT License

Copyright (c) $year $AUTHOR_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy...
EOF
chown "$NEO_USER:$NEO_USER" "$TARGET_DIR/LICENSE"

# --- package.json license field ---
jq '.license="MIT"' "$TARGET_DIR/package.json" > tmp && mv tmp "$TARGET_DIR/package.json"

# --- Git init & first commit ---
sudo -H -u "$NEO_USER" bash -lc "cd '$TARGET_DIR' && git init && git add . && git commit -m '[Kickstarter] Init $PROJECT_NAME'"

echo "🚀 Project $PROJECT_NAME installed in $TARGET_DIR"
