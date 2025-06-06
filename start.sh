#!/usr/bin/env bash

# =============================================================================
# create_neomnia_project.sh — Script de création d’un nouveau projet Next.js/React
# Basé sur le “kickstarter” neomnia-react (Charles Van Den Driessche – Neomnia © 2025)
#
# Usage :
#   sudo chmod +x create_neomnia_project.sh
#   sudo ./create_neomnia_project.sh
#
# Il :
# 1. Demande à l’utilisateur le nom du projet.
# 2. Crée /opt/<nom_du_projet> et y lance “create-next-app@latest”.
# 3. Installe ESLint, Prettier, Tailwind, etc., pour fournir une base “kickstarter”.
# 4. Génère .env.local depuis .env.example si besoin.
# 5. Démarre le serveur en mode dev.
# =============================================================================

set -e

# 1. Vérifier les prérequis
if ! command -v node &> /dev/null; then
  echo "❌ Node.js (≥ 14.x) n’est pas installé. Veuillez l’installer d’abord."
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "❌ npm n’est pas installé. Veuillez installer Node.js et npm."
  exit 1
fi

# 2. Lecture du nom de projet
read -rp "🔹 Quel nom pour le nouveau projet ? " PROJECT_NAME
# Enlever les espaces ou caractères invalides (optionnel)
PROJECT_NAME="${PROJECT_NAME// /-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Vous devez fournir un nom non vide."
  exit 1
fi

# 3. Définir le répertoire cible (sous /opt)
BASE_DIR="/opt"
TARGET_DIR="$BASE_DIR/$PROJECT_NAME"

# 4. Vérifier les droits et l’existence du dossier
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Ce script doit être exécuté en root (ou via sudo)."
  exit 1
fi

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Le dossier '$TARGET_DIR' existe déjà. Choisissez un autre nom ou supprimez-le."
  exit 1
fi

echo "ℹ️  Création du dossier projet : $TARGET_DIR"
mkdir -p "$TARGET_DIR"
chown "$SUDO_USER":"$SUDO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

# 5. Lancer create-next-app pour installer Next.js + React (dernier package)
echo
echo "→ Installation de Next.js/React dans '$TARGET_DIR'…"
# On se place sous l’utilisateur non-root pour installer proprement
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

# Générer un fichier tailwind.config.js minimal si nécessaire
# (vous pourrez ajuster le contenu plus tard)
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

# 8. Installer Prettier + eslint-config-prettier + eslint-plugin-prettier
echo
echo "→ Installation de Prettier + plugins ESLint…"
npm install -D prettier eslint-config-prettier eslint-plugin-prettier

# Créer un .prettierrc de base si inexistant
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

# 9. (Optionnel) Installer Husky + lint-staged
echo
echo "→ Installation de Husky + lint-staged pour hooks Git…"
npm install -D husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"

# Ajouter la section lint-staged dans package.json si absente
if ! grep -q "\"lint-staged\"" package.json; then
  # On injecte la configuration minimale sans écraser le reste
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

# 10. Copier .env.example vers .env.local si présent
if [ -f ".env.example" ] && [ ! -f ".env.local" ]; then
  echo
  echo "→ Copie de .env.example vers .env.local…"
  cp .env.example .env.local
  echo "⚠️  Complétez .env.local avant de lancer le projet."
fi

# 11. Premier commit Git (si git n’est pas déjà initialisé)
if [ ! -d ".git" ]; then
  echo
  echo "→ Initialisation d’un dépôt Git local…"
  git init
  git add .
  git commit -m "🎉 Initialisation du projet Next.js/React ($PROJECT_NAME)"
fi

# 12. Afficher la fin et lancer le dev server
echo
echo "✅ Le projet '$PROJECT_NAME' a été créé dans $TARGET_DIR"
echo "ℹ️  Pour y accéder :"
echo "    cd $TARGET_DIR"
echo
echo "→ Lancement du serveur en mode développement…"
echo "  (Appuyez sur Ctrl+C pour arrêter)"
npm run dev

# Fin du script
