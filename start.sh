#!/usr/bin/env bash

# =============================================================================
# start.sh — Kickstarter Next.js/React pour Neomnia (auto-évaluation complète)
#
# Ce script :
#   1. Vérifie la présence de Git, Node.js et npm, et les installe via apt si nécessaire.
#   2. Demande un nom de projet à l’utilisateur.
#   3. Crée /opt/<nom_du_projet> et y lance create-next-app@latest sous l’utilisateur neoweb.
#   4. Installe Tailwind, Prettier, ESLint, Husky, etc., toujours sous neoweb.
#   5. Termine en lançant “npm run dev” sous neoweb.
#
# Usage :
#   cd /opt/repos/neomnia-react
#   sudo chmod +x start.sh
#   sudo ./start.sh
#
# Auteur : Charles Van Den Driessche – Neomnia © 2025
# =============================================================================

set -euo pipefail

### 0. Vérifier qu’on est root (nécessaire pour apt-get et /opt)
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Ce script doit être lancé avec sudo (root)."
  exit 1
fi

### 1. Définir l’utilisateur qui devra posséder le projet
NEO_USER="neoweb"

### 2. Fonction pour vérifier/installer un paquet via apt
#    Usage : ensure_pkg <nom_du_paquet>
ensure_pkg() {
  PKG="$1"
  if ! dpkg -s "$PKG" &> /dev/null; then
    echo "ℹ️  Paquet '$PKG' manquant, installation en cours…"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$PKG"
    echo "✅ '$PKG' installé."
  else
    echo "ℹ️  '$PKG' déjà présent."
  fi
}

### 3. Vérifier Git
if ! command -v git &> /dev/null; then
  ensure_pkg git
else
  echo "ℹ️  Git est déjà installé (version : $(git --version))."
fi

### 4. Vérifier Node.js + npm
NODE_OK=false
if command -v node &> /dev/null; then
  # On vérifie uniquement la version majeure ≥ 14
  MAJOR=$(node -v | sed -E 's/^v([0-9]+)\..*/\1/')
  if [ "$MAJOR" -ge 14 ]; then
    echo "ℹ️  Node.js $(node -v) déjà installé."
    NODE_OK=true
  fi
fi

if [ "$NODE_OK" = false ]; then
  echo "ℹ️  Node.js (≥ 14) manquant ou trop vieux, installation en cours…"
  # Ajouter NodeSource (pour avoir une version récente) :
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 
  DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
  echo "✅ Node.js $(node -v) installé."
fi

if ! command -v npm &> /dev/null; then
  echo "ℹ️  npm manquant, installation via apt…"
  DEBIAN_FRONTEND=noninteractive apt-get install -y npm
  echo "✅ npm $(npm -v) installé."
else
  echo "ℹ️  npm $(npm -v) déjà présent."
fi

### 5. Demander le nom du projet
read -rp "🔹 Quel nom pour le nouveau projet Next.js/React ? " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME// /-}"    # remplacer espaces par tirets

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Vous devez fournir un nom de projet non vide."
  exit 1
fi

### 6. Préparer les chemins
BASE_DIR="/opt"
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Le dossier '$TARGET_DIR' existe déjà. Supprimez-le ou choisissez un autre nom."
  exit 1
fi

### 7. Créer le dossier de projet et ajuster droits
mkdir -p "$TARGET_DIR"
chown "$NEO_USER":"$NEO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

### 8. Créer le projet Next.js/React SOUS neoweb
echo
echo "→ Création de Next.js/React (latest) dans '$TARGET_DIR'…"
sudo -H -u "$NEO_USER" bash -c "cd '$BASE_DIR' && npx create-next-app@latest '$PROJECT_NAME' --use-npm --eslint --no-tailwind --no-src-dir"

### 9. Ajuster la propriété récursive du dossier
chown -R "$NEO_USER":"$NEO_USER" "$TARGET_DIR"

### 10. Installer Tailwind CSS + PostCSS + Autoprefixer sous neoweb
echo
echo "→ Installation de Tailwind CSS / PostCSS / Autoprefixer…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D tailwindcss postcss autoprefixer && npx tailwindcss init -p"

# Générer un tailwind.config.js minimal si absent
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

### 11. Installer Prettier + plugins ESLint sous neoweb
echo
echo "→ Installation de Prettier / eslint-config-prettier / eslint-plugin-prettier…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D prettier eslint-config-prettier eslint-plugin-prettier"

# Créer un .prettierrc si absent
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

### 12. Installer Husky + lint-staged sous neoweb
echo
echo "→ Installation de Husky / lint-staged…"
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm install -D husky lint-staged && npx husky install && npx husky add .husky/pre-commit \"npx lint-staged\""

# Injecter lint-staged dans package.json si absent
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

### 13. Copier .env.example vers .env.local si besoin (sous neoweb)
if [ -f "$TARGET_DIR/.env.example" ] && [ ! -f "$TARGET_DIR/.env.local" ]; then
  echo
  echo "→ Copie de .env.example vers .env.local…"
  sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && cp .env.example .env.local"
  echo "⚠️  N’oubliez pas de remplir .env.local."
fi

### 14. Initialiser Git + commit initial sous neoweb (si .git absent)
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo
  echo "→ Initialisation d’un dépôt Git local et commit initial…"
  sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && git init && git add . && git commit -m \"🎉 Initialisation du projet Next.js/React ($PROJECT_NAME)\""
fi

### 15. Message final et lancement du serveur dev
echo
echo "✅ Projet '$PROJECT_NAME' créé dans $TARGET_DIR."
echo "ℹ️  Pour continuer plus tard (en tant que neoweb) :"
echo "    cd $TARGET_DIR"
echo "    npm run dev"
echo
echo "→ Démarrage automatique du serveur en mode développement…"
echo "(appuyez sur Ctrl+C pour arrêter)"

# Lancer enfin npm run dev sous neoweb
sudo -H -u "$NEO_USER" bash -c "cd '$TARGET_DIR' && npm run dev"

# =========================================================================== #
# Fin du script
