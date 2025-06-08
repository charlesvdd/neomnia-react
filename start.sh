#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

################################################################################
# Script de création d'un projet Next.js + Tailwind + ESLint + i18n (+ PWA)
# Usage :
#   ./create_next_i18n_pwa.sh \
#      -n mon-projet \
#      -a "Auteur Nom" \
#      [-d /chemin/base] \
#      [-l "fr,en,es"] \
#      [-D fr] \
#      [-p]
# Options :
#   -n NOM         nom du projet (mandatory)
#   -a AUTEUR      nom pour LICENSE (MIT) (mandatory)
#   -d BASE_DIR    répertoire parent (default: cwd)
#   -l LOCALES     locales séparées par des virgules (default: fr,en)
#   -D DEFAULT     locale par défaut (default: première de la liste)
#   -p             activer PWA manifest.json (optional)
################################################################################

usage() {
  grep '^#' "$0" | sed -e 's/^#//'; exit 1
}

# valeurs par défaut
BASE_DIR=$(pwd)
LOCALES="fr,en"
DEFAULT_LOCALE=""
ENABLE_PWA=false

# parse options
while getopts "n:a:d:l:D:ph" opt; do
  case $opt in
    n) PROJECT_NAME="$OPTARG" ;; 
    a) AUTHOR="$OPTARG" ;; 
    d) BASE_DIR="$OPTARG" ;; 
    l) LOCALES="$OPTARG" ;; 
    D) DEFAULT_LOCALE="$OPTARG" ;; 
    p) ENABLE_PWA=true ;; 
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "${PROJECT_NAME-}" || -z "${AUTHOR-}" ]]; then
  echo "Erreur : -n et -a sont obligatoires." >&2
  usage
fi

# derive default locale
if [[ -z "$DEFAULT_LOCALE" ]]; then
  DEFAULT_LOCALE="${LOCALES%%,*}"
fi

TARGET="${BASE_DIR%/}/$PROJECT_NAME"

# create Next.js project
echo "→ Création du projet Next.js : $PROJECT_NAME"
npx create-next-app@latest "$PROJECT_NAME" \
  --use-npm --eslint --tailwind --src-dir

cd "$PROJECT_NAME"

# rewrite next.config.js with i18n (and optionally PWA)
CONFIG="next.config.js"
echo "→ Configuration i18n dans $CONFIG"
if \$ENABLE_PWA; then
  echo "→ Activation PWA via next-pwa"
  # installer next-pwa
  npm install -D next-pwa
  cat > "$CONFIG" <<EOF
const withPWA = require('next-pwa')({ dest: 'public' });

module.exports = withPWA({
  i18n: {
    locales: [${LOCALES//,/','/}],
    defaultLocale: '$DEFAULT_LOCALE',
    localeDetection: true,
  },
});
EOF
else
  cat > "$CONFIG" <<EOF
module.exports = {
  i18n: {
    locales: [${LOCALES//,/','/}],
    defaultLocale: '$DEFAULT_LOCALE',
    localeDetection: true,
  },
};
EOF
fi

# créer dossiers de locales
echo "→ Création des fichiers de traduction (locales)"
mkdir -p locales
IFS=',' read -ra LANGS <<< "$LOCALES"
for L in "${LANGS[@]}"; do
  mkdir -p locales/$L
  cat > locales/$L/common.json <<EOF
{
  "welcome": "Bienvenue",
  "hello": "Bonjour"
}
EOF
done

# générer manifest si PWA
if \$ENABLE_PWA; then
  echo "→ Génération de public/manifest.json"
  mkdir -p public/icons
  cat > public/manifest.json <<EOF
{
  "name": "$PROJECT_NAME",
  "short_name": "$PROJECT_NAME",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
EOF
  echo "(Placez vos icônes 192x192 et 512x512 dans public/icons/)"
fi

# créer license MIT
echo "→ Génération LICENSE MIT"
echo "MIT License

Copyright (c) $(date +%Y) $AUTHOR

Permission is hereby granted...
" > LICENSE

# init Git
echo "→ Initialisation Git"
git init
git add .
git commit -m "chore: scaffolder Next.js + i18n$( \$ENABLE_PWA && echo "+PWA" )"

# résumé
cat <<EOF

🎉 Projet '$PROJECT_NAME' généré dans $(pwd).
Available scripts:
  npm install   # installer les dépendances
  npm run dev   # démarrer le serveur de dev

Locales: $LOCALES (default: $DEFAULT_LOCALE)
EOF
