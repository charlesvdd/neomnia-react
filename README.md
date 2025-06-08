# neomnia-react

Kickstarter Next.js / React pour Neomnia

## Description

Ce dépôt fournit une base (« kickstarter ») pour démarrer rapidement un projet Next.js/React sous l’écosystème Neomnia.
Il inclut une configuration minimale pour lancer un site Next.js avec React, ESLint, Prettier et Tailwind CSS, ainsi que les bonnes pratiques de structure de dossier et de commits.

## Auteur et Licence

* **Auteur :** Charles Van Den Driessche – Neomnia
* **Année :** 2025
* **Site Web :** [www.neomnia.net](https://www.neomnia.net)
* **Licence :** GNU General Public License v3.0 (voir le fichier [LICENSE](./LICENSE) pour le texte complet).

```
neomnia-react/
├── .env.example           # Exemple de variables d’environnement
├── .eslintrc.json         # Configuration ESLint
├── .gitignore
├── .prettierrc            # Configuration Prettier
├── LICENSE                # Licence GNU GPL v3.0
├── README.md              # Ce fichier
├── next.config.js         # Configuration Next.js
├── package.json
├── postcss.config.js      # Configuration PostCSS pour Tailwind
├── tailwind.config.js     # Configuration Tailwind CSS
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
```

## Prérequis

* **Node.js** ≥ 14.x ou supérieur
* **npm** ou **yarn**
* Accès à un terminal **bash**

## Installation

1. **Cloner le dépôt**

   ```bash
   git clone git@github.com:VotreCompte/neomnia-react.git
   cd neomnia-react
   ```

## Usage

1. **Installer les dépendances**

   ```bash
   npm install
   ```

2. **Démarrer le serveur de développement**

   ```bash
   npm run dev
   ```

3. **Ouvrir votre navigateur**
   Rendez-vous sur [http://localhost:3000](http://localhost:3000) pour voir l’application.

## Structure du projet

Après installation, votre projet ressemblera à ceci :

```
mon-projet-react/
├── node_modules/         # Dépendances installées
├── public/               # Fichiers statiques
├── src/                  # Code source
│   ├── components/       # Composants React
│   ├── pages/            # Pages Next.js
│   └── styles/           # Styles (CSS/Tailwind)
├── .eslintrc.json        # ESLint config
├── .prettierrc           # Prettier config
├── .gitignore
├── next.config.js        # Next.js config
├── package.json
└── tailwind.config.js    # Tailwind config
```

## Ajouts facultatifs

Pour ajouter Prettier, Husky et lint-staged :

```bash
npm install -D prettier eslint-config-prettier eslint-plugin-prettier husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
```

Ensuite, créez les fichiers `.prettierrc` et `.lintstagedrc` si besoin.

---

Bonne utilisation ! N’hésitez pas à ouvrir une issue si vous rencontrez un problème ou souhaitez proposer une amélioration.
