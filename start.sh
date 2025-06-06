#!/usr/bin/env bash

# =============================================================================
# start.sh — Kickstarter Next.js/React pour Neomnia (version corrigée)
#   - Auto-évaluation complète des prérequis (Git, Node.js, npm)
#   - Création sous /opt/<nom_du_projet>
#   - Utilisation de “npm exec” plutôt que “npx”
#   - Tout npm se fait sous l’utilisateur neoweb pour éviter “could not determine executable”
#
# Usage :
#   cd /opt/repos/neomnia-react
#   sudo chmod +x start.sh
#   sudo ./start.sh
#
# Auteur : Charles Van Den Driessche – Neomnia © 2025
# =============================================================================

set -euo pipefail

### 0. Vérifier qu’on est root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Ce script doit être lancé avec sudo (root)."
  exit 1
fi

### 1. Définir l’utilisateur
NEO_USER="neoweb"

### 2. Fonction pour assurer l’installation d’un paquet apt-get
ensure_pkg() {
  PKG="$1"
  if ! dpkg -s "$PKG" &> /dev/null; then
    echo "ℹ️  Paquet '$PKG' absent, installation…"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$PKG"
    echo "✅ '$PKG' installé."
  else
    echo "ℹ️  '$PKG' déjà installé."
  fi
}

### 3. Vérifier/installer Git
if ! command -v git &> /dev/null; then
  ensure_pkg git
else
  echo "ℹ️  Git déjà présent (version : $(git --version))."
fi

### 4. Vérifier/installer Node.js (>=14) et npm
NODE_OK=false
if command -v node &> /dev/null; then
  MAJOR=$(node -v | sed -E 's/^v([0-9]+)\..*/\1/')
  if [ "$MAJOR" -ge 14 ]; then
    echo "ℹ️  Node.js $(node -v) déjà installé."
    NODE_OK=true
  fi
fi

if [ "$NODE_OK" = false ]; then
  echo "ℹ️  Node.js manquant ou version < 14, installation via NodeSource…"
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 2> /dev/null
  DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
  echo "✅ Node.js $(node -v) installé."
fi

if ! command -v npm &> /dev/null; then
  echo "ℹ️  npm manquant, installation vía apt…"
  DEBIAN_FRONTEND=noninteractive apt-get install -y npm
  echo "✅ npm $(npm -v) installé."
else
  echo "ℹ️  npm $(npm -v) déjà présent."
fi

### 5. Demander le nom du projet
read -rp "🔹 Quel nom pour le nouveau projet Next.js/React ? " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME// /-}"  # remplacer espaces par tirets

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Nom de projet vide. Annulation."
  exit 1
fi

### 6. Préparer chemins
BASE_DIR="/opt"
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Le dossier '$TARGET_DIR' existe déjà. Choisissez un autre nom ou supprimez-le."
  exit 1
fi

### 7. Créer /opt/<nom_du_projet> et ajuster droits
mkdir -p "$TARGET_DIR"
chown "$NEO_USER":"$NEO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

### 8. Création du projet Next.js/React sous neoweb
echo
echo "→ Création du projet Next.js/React (latest) dans '$TARGET_DIR'…"
sudo -H -u "$NEO_USER" bash -c "cd '$BASE_DIR' && npx create-next-app@latest '$PROJECT_NAME' --use-npm --eslint --no-tailwind --no-src-dir"

### 9. Ajuster propriétaire – tout doit appartenir à neoweb
chown -R "$NEO_USER":"$NEO_USER" "$TARGET_DIR"

### 10. Installer Tailwind CSS + PostCSS + Autoprefixer (sous neoweb)
echo
echo "→ Installation de Tailwind / PostCSS / Autoprefixer…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D tailwindcss postcss autoprefixer"

# Lancer la commande d'initialisation en deux temps pour éviter l'erreur npm
echo "   • Initialisation de Tailwind CSS…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm exec tailwindcss init -p"

### 11. Générer un tailwind.config.js minimal si absent
if [ ! -f "$TARGET_DIR/tailwind.config.js" ]; then
  cat > "$TARGET_DIR/tailwind.config.js" << 'TAILWIND'
/** @type {import('tailwindcss').Config} */
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
TAILWIND
  chown "$NEO_USER":"$NEO_USER" "$TARGET_DIR/tailwind.config.js"
fi

### 12. Installer Prettier + eslint-config-prettier + eslint-plugin-prettier (sous neoweb)
echo
echo "→ Installation de Prettier / ESLint-Prettier…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D prettier eslint-config-prettier eslint-plugin-prettier"

# Créer le fichier .prettierrc si absent
if [ ! -f "$TARGET_DIR/.prettierrc" ]; then
  cat > "$TARGET_DIR/.prettierrc" << 'PRETTIER'
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "trailingComma": "es5"
}
PRETTIER
  chown "$NEO_USER":"$NEO_USER" "$TARGET_DIR/.prettierrc"
fi

### 13. Installer Husky + lint-staged (sous neoweb)
echo
echo "→ Installation de Husky / lint-staged…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D husky lint-staged"

# Initialiser Husky et ajouter hook pre-commit
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm exec husky install && npm exec husky add .husky/pre-commit \"npx lint-staged\""

# Si lint-staged manquant dans package.json, l'ajouter
if ! grep -q "\"lint-staged\"" "$TARGET_DIR/package.json"; then
  sudo -H -u "$NEO_USER" bash << EOF
cd "$TARGET_DIR"
node << 'JS'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json'));
pkg['lint-staged'] = {
  "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{css,scss,md}": ["prettier --write"]
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
JS
EOF
fi

### 14. Copier .env.example → .env.local si besoin (sous neoweb)
if [ -f "$TARGET_DIR/.env.example" ] && [ ! -f "$TARGET_DIR/.env.local" ]; then
  echo
  echo "→ Copie de .env.example vers .env.local…"
  sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && cp .env.example .env.local"
  echo "⚠️  N’oubliez pas de renseigner .env.local."
fi

### 15. Initialiser Git + commit initial (sous neoweb) si .git absent
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo
  echo "→ Initialisation d’un dépôt Git local + commit initial…"
  sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && git init && git add . && git commit -m \"🎉 Initialisation du projet Next.js/React ($PROJECT_NAME)\""
fi

### 16. Message final + lancer npm run dev en tant que neoweb
echo
echo "✅ Projet '$PROJECT_NAME' créé dans $TARGET_DIR."
echo "ℹ️  Pour continuer plus tard (en tant que neoweb) :"
echo "    cd $TARGET_DIR"
echo "    npm run dev"
echo
echo "→ Démarrage automatique du serveur en mode développement…"
echo "(Ctrl+C pour arrêter)"

sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm run dev"

# Fin du script
