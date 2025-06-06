#!/usr/bin/env bash

# =============================================================================
# start.sh — Script de kickstarter Next.js/React pour Neomnia (2025)
# - Installe Node.js/​npm si absent
# - Demande à l’utilisateur le nom du projet
# - Crée /opt/<nom_du_projet> et y lance create-next-app@latest
# - Ajoute Tailwind, Prettier, ESLint, Husky, etc.
# - Démarre le serveur en mode dev
# Auteur : Charles Van Den Driessche – Neomnia © 2025
#
# Usage :
#   # 1. Copier ce fichier sous /opt/repos/neomnia-react/start.sh
#   # 2. cd /opt/repos/neomnia-react
#   chmod +x start.sh
#   sudo ./start.sh
# =============================================================================

set -e

# 0. Vérifier qu’on est bien root (nécessaire pour installer Node et créer /opt/…)
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Ce script doit être exécuté en root (ou via sudo)."
  exit 1
fi

# 1. Installer Node.js + npm si nécessaire
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "ℹ️  Node.js ou npm introuvable. Installation en cours…"
  apt-get update
  apt-get install -y nodejs npm
  # Vérifier que la version de Node est >= 14
  NODE_MAJOR=$(node -v | sed 's/^v\([0-9]*\)\..*$/\1/')
  if [ "$NODE_MAJOR" -lt 14 ]; then
    echo "⚠️  La version de Node installée (<14) risque de ne pas convenir. Vous pouvez installer manuellement une version >=14 depuis NodeSource."
  else
    echo "✅ Node.js $(node -v) installé."
  fi
fi

# 2. Vérification de npm
if ! command -v npm &> /dev/null; then
  echo "❌ npm n’a pas été trouvé après installation. Veuillez vérifier manuellement."
  exit 1
fi

# 3. Demander le nom du projet
read -rp "🔹 Quel nom pour le nouveau projet Next.js/React ? " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME// /-}"  # remplacer espaces par tirets
if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Vous devez fournir un nom non vide."
  exit 1
fi

# 4. Définir et créer le répertoire cible sous /opt
BASE_DIR="/opt"
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Le dossier '$TARGET_DIR' existe déjà. Choisissez un autre nom ou supprimez-le."
  exit 1
fi

echo "ℹ️  Création du répertoire projet : $TARGET_DIR"
mkdir -p "$TARGET_DIR"
chown "$SUDO_USER":"$SUDO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

# 5. Lancer create-next-app@latest en tant qu’utilisateur normal
echo
echo "→ Installation de Next.js/React (latest) dans '$TARGET_DIR'…"
sudo -u "$SUDO_USER" bash << EOF
cd "$BASE_DIR"
npx create-next-app@latest "$PROJECT_NAME" --use-npm --eslint --no-tailwind --no-src-dir
EOF

# 6. Se placer dans le dossier fraîchement créé
cd "$TARGET_DIR"

# 7. Installer Tailwind CSS + PostCSS + Autoprefixer
echo
echo "→ Installation de Tailwind CSS + PostCSS + Autoprefixer…"
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Générer un tailwind.config.js basique
cat > tailwind.config.js << 'TAILWINDCONFIG'
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
TAILWINDCONFIG

# 8. Installer Prettier + plugins ESLint-Prettier
echo
echo "→ Installation de Prettier + eslint-config-prettier + eslint-plugin-prettier…"
npm install -D prettier eslint-config-prettier eslint-plugin-prettier

# Créer un .prettierrc minimal si inexistant
if [ ! -f ".prettierrc" ]; then
  cat > .prettierrc << 'PRETTIER'
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "trailingComma": "es5"
}
PRETTIER
fi

# 9. Installer Husky + lint-staged
echo
echo "→ Installation de Husky + lint-staged pour hooks Git…"
npm install -D husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"

# Ajouter lint-staged au package.json si absent
if ! grep -q "\"lint-staged\"" package.json; then
  node - << 'EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json'));
pkg['lint-staged'] = {
  "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{css,scss,md}": ["prettier --write"]
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOF
fi

# 10. Copier .env.example → .env.local si besoin
if [ -f ".env.example" ] && [ ! -f ".env.local" ]; then
  echo
  echo "→ Copie de .env.example vers .env.local…"
  cp .env.example .env.local
  echo "⚠️  N’oubliez pas de compléter .env.local avant de lancer le projet."
fi

# 11. Initialiser Git si nécessaire
if [ ! -d ".git" ]; then
  echo
  echo "→ Initialisation d’un dépôt Git local…"
  git init
  git add .
  git commit -m "🎉 Initialisation Kickstart Next.js/React ($PROJECT_NAME)"
fi

# 12. Fin et lancement du serveur en mode développement
echo
echo "✅ Projet '$PROJECT_NAME' créé dans $TARGET_DIR"
echo "ℹ️  Pour y accéder : cd $TARGET_DIR"
echo
echo "→ Lancement du serveur en mode dev (http://localhost:3000)…"
npm run dev

# Fin du script
