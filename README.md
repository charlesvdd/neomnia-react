# neomnia-react

Kickstarter Next.js / React pour Neomnia

## Description

Ce dépôt fournit une base (« kickstarter ») pour démarrer rapidement un projet Next.js/React sous l’écosystème Neomnia.  
Il inclut une configuration minimale pour lancer un site Next.js avec React, ESLint, Prettier et Tailwind CSS, ainsi que les bonnes pratiques de structure de dossier et de commits.

## Auteur et Licence

- **Auteur :** Charles Van Den Driessche – Neomnia  
- **Année :** 2025  
- **Site Web :** [www.neomnia.net](https://www.neomnia.net)  
- **Licence :** GNU General Public License v3.0 (voir le fichier [LICENSE](./LICENSE) pour le texte complet).

neomnia-react/
├── .env.example           # Exemple de variables d’environnement
├── .eslintrc.json         # Configuration ESLint
├── .gitignore
├── .prettierrc            # Configuration Prettier
├── LICENSE                # Licence GNU GPL v3.0
├── README.md              # Ce fichier
├── next.config.js         # Configuration Next.js
├── package.json
├── postcss.config.js      # (si Tailwind installé)
├── tailwind.config.js     # (si Tailwind installé)
├── tsconfig.json          # (si TypeScript sélectionné)
├── public/                # Ressources statiques (images, favicon…)
├── src/                   # Code source
│   ├── components/        # Composants React réutilisables
│   ├── pages/             # Pages Next.js (routes)
│   │   ├── _app.tsx
│   │   ├── index.tsx
│   │   └── api/           # Endpoints API (si nécessaire)
│   └── styles/            # Fichiers CSS/Tailwind
└── jest.config.js         # (si tests configurés)


## Prérequis

- Node.js ≥ 14.x  
- npm ou yarn  
- Accès à un terminal bash

## Installation

1. **Cloner le dépôt**  
   ```bash
   git clone git@github.com:VotreCompte/neomnia-react.git
   cd neomnia-react
