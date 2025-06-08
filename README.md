Here is the translation of the script into English:

```markdown
# neomnia-react

Next.js / React Kickstarter for Neomnia

## Description

This repository provides a base ("kickstarter") to quickly start a Next.js/React project within the Neomnia ecosystem.
It includes a minimal setup to launch a Next.js site with React, ESLint, Prettier, and Tailwind CSS, along with best practices for folder structure and commits.

## Author and License

* **Author:** Charles Van Den Driessche – Neomnia
* **Year:** 2025
* **Website:** [www.neomnia.net](https://www.neomnia.net)
* **License:** GNU General Public License v3.0 (see the [LICENSE](./LICENSE) file for the full text).

```
neomnia-react/
├── .env.example           # Environment variables example
├── .eslintrc.json         # ESLint configuration
├── .gitignore
├── .prettierrc            # Prettier configuration
├── LICENSE                # GNU GPL v3.0 License
├── README.md              # This file
├── next.config.js         # Next.js configuration
├── package.json
├── postcss.config.js      # PostCSS configuration for Tailwind
├── tailwind.config.js     # Tailwind CSS configuration
├── tsconfig.json          # (if TypeScript is selected)
├── public/                # Static resources (images, favicon, etc.)
├── src/                   # Source code
│   ├── components/        # Reusable React components
│   ├── pages/             # Next.js pages (routes)
│   │   ├── _app.tsx
│   │   ├── index.tsx
│   │   └── api/           # API endpoints (if necessary)
│   └── styles/            # CSS/Tailwind files
└── jest.config.js         # (if tests are configured)
```

## Prerequisites

* **Node.js** ≥ 14.x or higher
* **npm** or **yarn**
* Access to a **bash** terminal

## Installation

1. **Clone the repository**

   ```bash
   git clone git@github.com:YourAccount/neomnia-react.git
   cd neomnia-react
   ```

## Usage

1. **Install dependencies**

   ```bash
   npm install
   ```

2. **Start the development server**

   ```bash
   npm run dev
   ```

3. **Open your browser**
   Go to [http://localhost:3000](http://localhost:3000) to see the application.

## Project Structure

After installation, your project will look like this:

```
my-react-project/
├── node_modules/         # Installed dependencies
├── public/               # Static files
├── src/                  # Source code
│   ├── components/       # React components
│   ├── pages/            # Next.js pages
│   └── styles/           # Styles (CSS/Tailwind)
├── .eslintrc.json        # ESLint config
├── .prettierrc           # Prettier config
├── .gitignore
├── next.config.js        # Next.js config
├── package.json
└── tailwind.config.js    # Tailwind config
```

## Optional Additions

To add Prettier, Husky, and lint-staged:

```bash
npm install -D prettier eslint-config-prettier eslint-plugin-prettier husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
```

Then, create the `.prettierrc` and `.lintstagedrc` files if needed.

---

Enjoy! Feel free to open an issue if you encounter a problem or wish to suggest an improvement.
```
