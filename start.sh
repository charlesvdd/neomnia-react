#!/usr/bin/env bash

# =============================================================================
# start.sh — Script pour initialiser et démarrer le projet neomnia-react
# Auteur : Charles Van Den Driessche – Neomnia © 2025
# Usage : 
#   chmod +x start.sh
#   ./start.sh
# =============================================================================

# Arrêter le script en cas d'erreur
set -e

# 1. Vérifier que Node.js et npm sont installés
if ! command -v node &> /dev/null; then
  echo "❌ Node.js n'est pas installé. Veuillez installer Node.js ≥ 14.x avant de continuer."
  exit 1
fi
if ! command -v npm &> /dev/null; then
  echo "❌ npm n'est pas installé. Veuillez installer npm ou yarn avant de continuer."
  exit 1
fi

# 2. Définir quelques couleurs pour l’affichage (facultatif)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Pas de couleur

# 3. Message de démarrage
echo -e "${CYAN}=== Démarrage du script neomnia-react ===${NC}"
echo

# 4. Installer ou mettre à jour les dépendances si node_modules est manquant
if [ ! -d "node_modules" ]; then
  echo -e "${GREEN}→ Installation des dépendances (npm install)...${NC}"
  npm install
  echo
else
  echo -e "${GREEN}→ node_modules déjà présent, mise à jour des dépendances (npm ci)...${NC}"
  npm ci
  echo
fi

# 5. Copier l’exemple de fichier .env si nécessaire
if [ ! -f ".env.local" ] && [ -f ".env.example" ]; then
  echo -e "${GREEN}→ Copie de .env.example vers .env.local...${NC}"
  cp .env.example .env.local
  echo "⚠️  N’oubliez pas de compléter .env.local avec vos propres variables d’environnement."
  echo
fi

# 6. Lancer les vérifications de code (ESLint + Prettier)
echo -e "${GREEN}→ Vérification de la qualité du code (lint + format)...${NC}"
npm run lint || echo -e "${RED}⚠️  Des erreurs de lint subsistent (vous pouvez corriger puis relancer).${NC}"
npm run format
echo

# 7. Démarrer le serveur en mode développement
echo -e "${GREEN}→ Lancement du serveur en mode développement → http://localhost:3000${NC}"
npm run dev

# Fin du script
