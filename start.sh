#!/usr/bin/env bash
# -*- coding: utf-8 -*-

################################################################################
# Script d’installation d’un projet Next.js/React + Tailwind + outils de dev  #
# - Vérifie et installe Node.js ≥ 20 si nécessaire                              #
# - Crée le projet Next.js/React avec la dernière version de create-next-app   #
# - Installe Tailwind CSS, Prettier, ESLint, Husky, lint-staged, etc.           #
# - Génère un fichier LICENSE (MIT) automatiquement                              #
# - Affiche une « maquette graphique » (ASCII + émojis) pour chaque étape        #
# - Initialise un dépôt Git et fait le premier commit                            #
################################################################################

set -euo pipefail
IFS=$'\n\t'

# --------------------------------------
# Configuration initiale
# --------------------------------------

LOG_FILE="/var/log/nextjs_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

NEO_USER="neoweb"           # Utilisateur non-root qui possédera le projet
NODE_MAJOR_MINIMUM=20       # Version majeure minimale de Node.js requise
BASE_DIR="/opt"             # Répertoire parent où seront créés les projets

################################################################################
# FONCTIONS UTILITAIRES
################################################################################

# Affiche un encadré ASCII avec une ligne de séparation et un texte centré
draw_banner() {
  local text="$1"
  local width=72
  local border_line
  border_line=$(printf '=%.0s' $(seq 1 $width))
  echo -e "\n\033[1;34m$border_line\033[0m"
  printf "\033[1;34m| %-${width}s |\033[0m\n" "$text"
  echo -e "\033[1;34m$border_line\033[0m\n"
}

# Affiche un message d’erreur et quitte
error_exit() {
  echo -e "❌ \033[1;31mErreur : $1\033[0m"
  exit 1
}

# Vérifie si un paquet Debian est installé, sinon l’installe
ensure_pkg() {
  local pkg="$1"
  if ! dpkg -s "$pkg" &> /dev/null; then
    echo "ℹ️  Paquet '$pkg' manquant, installation en cours…"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg"
    echo "✅  '$pkg' installé."
  else
    echo "ℹ️  '$pkg' déjà installé."
  fi
}

# Récupère la version majeure de Node.js (entier)
get_node_major() {
  if command -v node &> /dev/null; then
    # Supprime le "v" et garde la partie avant le premier point
    node -v | cut -d. -f1 | sed 's/v//'
  else
    echo "0"
  fi
}

# Installe Node.js à la version LTS la plus récente (20.x) via NodeSource
install_node_latest() {
  echo "→ Installation de Node.js >= ${NODE_MAJOR_MINIMUM}…"
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR_MINIMUM}.x | bash - \
    || error_exit "Impossible de télécharger le script NodeSource."
  apt-get install -y nodejs \
    || error_exit "Installation de nodejs a échoué."
  echo "✅  Node.js ($(node -v)) et npm ($(npm -v)) installés."
}

# Vérifie que Node.js est installé et >= NODE_MAJOR_MINIMUM, sinon installe/upgrade
ensure_node() {
  local current_major
  current_major=$(get_node_major)
  if [ "$current_major" -lt "$NODE_MAJOR_MINIMUM" ]; then
    echo "⚠️  Version de Node.js insuffisante (actuelle : $(node -v) / $current_major)."
    install_node_latest
  else
    echo "ℹ️  Node.js est à jour (version : $(node -v))."
  fi
}

# Exécute une commande, capture stderr dans un buffer temporaire pour analyse
# Si on détecte un EBADENGINE, on réinstalle Node.js puis on relance une seule fois
run_with_retry_on_engine_error() {
  local cmd="$*"
  local tmp_err
  tmp_err=$(mktemp)
  if ! bash -c "$cmd" 2>"$tmp_err"; then
    if grep -q "EBADENGINE" "$tmp_err"; then
      echo "⚠️  Erreur EBADENGINE détectée lors de : $cmd"
      echo "→ Mise à jour de Node.js et nouvelle tentative…"
      install_node_latest
      rm "$tmp_err"
      # Relance une seule fois la commande
      bash -c "$cmd" || error_exit "La commande '$cmd' a échoué même après mise à jour de Node."
    else
      cat "$tmp_err" 1>&2
      rm "$tmp_err"
      error_exit "La commande '$cmd' a échoué."
    fi
  fi
  rm "$tmp_err"
}

################################################################################
# DÉBUT DU SCRIPT
################################################################################

# 1) Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
  error_exit "Ce script doit être lancé avec sudo (root)."
fi

draw_banner "📦  DÉMARRAGE DU SCRIPT D’INSTALLATION Next.js/React"

# 2) Détecter/install Git
if ! command -v git &> /dev/null; then
  ensure_pkg git
else
  echo "ℹ️  Git déjà installé (version : $(git --version))."
fi

# 3) Vérifier/installer Node.js ≥ 20
ensure_node

# 4) Vérifier/installer npm (dans le cas où Node aurait été installé sans npm)
if ! command -v npm &> /dev/null; then
  echo "ℹ️  npm non détecté, installation en cours…"
  ensure_pkg npm
else
  echo "ℹ️  npm déjà présent (version : $(npm -v))."
fi

# 5) Demander le nom de projet
echo -ne "\n🔹 Quel nom pour le nouveau projet Next.js/React ? "
read -r PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME// /-}"   # Remplace espaces par tirets

if [ -z "$PROJECT_NAME" ]; then
  error_exit "Nom de projet vide. Abandon."
fi

TARGET_DIR="$BASE_DIR/$PROJECT_NAME"

# 6) Vérifier que le dossier n’existe pas déjà
if [ -d "$TARGET_DIR" ]; then
  error_exit "Le dossier '$TARGET_DIR' existe déjà. Choisissez un autre nom ou supprimez-le."
fi

# 7) Créer le répertoire et régler les droits
mkdir -p "$TARGET_DIR"
chown "$NEO_USER:$NEO_USER" "$TARGET_DIR"
chmod 755 "$TARGET_DIR"

draw_banner "🗂️  Création du dossier du projet dans : $TARGET_DIR"

# 8) Exécution de create-next-app avec gestion d’erreurs EBADENGINE
echo "→ Création du projet Next.js/React (dernier template)…"
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$BASE_DIR' && npx create-next-app@latest '$PROJECT_NAME' --use-npm --eslint --no-tailwind --no-src-dir\""

draw_banner "⚙️  Projet Next.js/React créé"

# 9) Installation des dépendances supplémentaires
echo "→ Installation de Tailwind CSS et dépendances de développement…"
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npm install -D tailwindcss postcss autoprefixer prettier eslint-config-prettier eslint-plugin-prettier husky lint-staged\""

draw_banner "✨  Tailwind, Prettier, ESLint, Husky, lint-staged installés"

# 10) Initialisation de Tailwind CSS (tailwind.config.js & postcss.config.js)
draw_banner "✨  Initialisation de Tailwind CSS (tailwind.config.js & postcss.config.js)"

# 10.1) Vérifier que tailwindcss est présent dans node_modules/.bin
if [ ! -f "$TARGET_DIR/node_modules/.bin/tailwindcss" ]; then
  echo "⚠️  Binaire 'tailwindcss' introuvable localement. Relance de 'npm install'…"
  run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npm install\""
  # Si, après ça, le binaire est toujours introuvable, installer globalement
  if [ ! -f "$TARGET_DIR/node_modules/.bin/tailwindcss" ]; then
    echo "⚠️  Le binaire 'tailwindcss' est toujours introuvable. Installation en global…"
    npm install -g tailwindcss || error_exit "Impossible d’installer Tailwind en global."
  fi
fi

# 10.2) Lancer npx tailwindcss init -p (avec retry EBADENGINE)
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npx tailwindcss init -p\""

# 10.3) Écraser/mettre à jour le fichier tailwind.config.js généré
cat > "$TARGET_DIR/tailwind.config.js" << 'TAILWIND_CFG'
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
TAILWIND_CFG

echo "✅  tailwind.config.js généré et postcss.config.js initialisé."
# 10.4) Écraser/mettre à jour le fichier postcss.config.js généré

# 11) Création du fichier .prettierrc
cat > "$TARGET_DIR/.prettierrc" << 'PRETTIER_CFG'
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "trailingComma": "es5"
}
PRETTIER_CFG

echo "✅  .prettierrc généré."

# 12) Initialisation de Husky + hook pre-commit pour lint-staged
echo "→ Configuration de Husky et lint-staged…"
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npx husky install\""
run_with_retry_on_engine_error "sudo -H -u \"$NEO_USER\" bash -lc \"cd '$TARGET_DIR' && npx husky add .husky/pre-commit \\\"npx lint-staged\\\"\""

cat > "$TARGET_DIR/.lintstagedrc" << 'LINTSTAGED_CFG'
{
  "*. {js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{css,scss,md}": ["prettier --write"]
}
LINTSTAGED_CFG

echo "✅  Husky + lint-staged configurés."

# 13) Copie .env.example vers .env.local si présent
if [ -f "$TARGET_DIR/.env.example" ]; then
  sudo -H -u "$NEO_USER" bash -lc "cd '$TARGET_DIR' && cp .env.example .env.local"
  echo "✅  .env.local copié depuis .env.example."
fi

# 14) Génération automatique du fichier LICENSE (MIT)
echo -ne "\n🔹 Nom de l’auteur pour la licence (ex. « Jean Dupont ») : "
read -r AUTHOR_NAME
if [ -z "$AUTHOR_NAME" ]; then
  error_exit "Auteur vide pour la licence. Abandon."
fi

YEAR=$(date +%Y)
LICENSE_FILE="$TARGET_DIR/LICENSE"
cat > "$LICENSE_FILE" << LICENSE_TXT
MIT License

Copyright (c) $YEAR $AUTHOR_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[Texte complet de la licence MIT ici…]
LICENSE_TXT

chown "$NEO_USER:$NEO_USER" "$LICENSE_FILE"
chmod 644 "$LICENSE_FILE"
echo "✅  Fichier LICENSE (MIT) généré avec auteur='$AUTHOR_NAME'."

# 15) Mise à jour du champ 'license' dans package.json
echo "→ Ajout du champ \"license\": \"MIT\" dans package.json…"
sudo -H -u "$NEO_USER" bash -lc "
  cd '$TARGET_DIR'
  # On utilise jq si disponible, sinon on édite en brut
  if command -v jq &> /dev/null; then
    jq '.license = \"MIT\"' package.json > tmp_pkg.json && mv tmp_pkg.json package.json
  else
    # Ajoute manuellement la ligne "license": "MIT", avant la dernière accolade
    sed -i.bak -e 's/}$//g' package.json
    echo '  ,\"license\": \"MIT\"' >> package.json
    echo '}' >> package.json
  fi
"
echo "✅  Champ license ajouté dans package.json."

# 16) Initialisation du dépôt Git
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "→ Initialisation du dépôt Git…"
  sudo -H -u "$NEO_USER" bash -lc "
    cd '$TARGET_DIR'
    git init
    git add .
    git commit -m \"[Kickstarter] Initialisation du projet Next.js/React ($PROJECT_NAME)\"
  "
  echo "✅  Premier commit effectué."
else
  echo "ℹ️  Un dépôt Git existe déjà, pas de réinitialisation."
fi

# 17) Finalisation et démarrage du serveur en mode dev
draw_banner "🏁  INSTALLATION TERMINÉE"
echo "→ Vous pouvez maintenant vous placer dans '$TARGET_DIR' et lancer : npm run dev"
echo "🎉 Projet '$PROJECT_NAME' prêt à l’emploi !"

################################################################################
# FIN DU SCRIPT
################################################################################
