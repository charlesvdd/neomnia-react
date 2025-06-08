# create\_next\_i18n\_pwa.sh

This Bash script automates the creation of a complete **Next.js** project that includes:

* **Next.js** setup with Tailwind CSS, ESLint, and a `src/` directory structure
* Native **i18n** configuration for multiple locales
* Optional **PWA** support via `next-pwa` and automatic `manifest.json` generation
* `locales/` directory with JSON translation files for each locale
* Automatic **MIT license** file generation using the provided author name
* Git repository initialization with an initial commit

---

## Prerequisites

* **Node.js** ≥ 16.x
* **npm** or **yarn**
* **bash** shell (Linux/macOS)
* Write permissions in the target directory

---

## Installation

1. Navigate to the directory where you want to store the script:

   ```bash
   cd ~/scripts
   ```
2. Download the script (via `curl` or by cloning the repo):

   ```bash
   curl -fsSL -o create_next_i18n_pwa.sh \
     https://raw.githubusercontent.com/charlesvdd/neomnia-react/main/create_next_i18n_pwa.sh
   ```
3. Make it executable:

   ```bash
   chmod +x create_next_i18n_pwa.sh
   ```

---

## Usage

```bash
./create_next_i18n_pwa.sh -n <project_name> -a "<Author Name>" [options]
```

### Available Options

| Option        | Description                                                          | Default              |
| ------------- | -------------------------------------------------------------------- | -------------------- |
| `-n <name>`   | **(Required)** The name of the project to create                     | —                    |
| `-a <author>` | **(Required)** Author name for the MIT license file                  | —                    |
| `-d <dir>`    | Base directory where the new project folder will be created          | Current directory    |
| `-l <locals>` | Comma-separated list of locales (e.g. `"fr,en,es"`)                  | `fr,en`              |
| `-D <locale>` | Default locale (must be one of those listed with `-l`)               | First locale in list |
| `-p`          | Enable PWA support (install `next-pwa` and generate `manifest.json`) | Disabled             |
| `-h`          | Display this help message                                            | —                    |

### Examples

* **Basic i18n** (French/English):

  ```bash
  ./create_next_i18n_pwa.sh -n my-app -a "John Doe"
  ```

* **i18n + PWA** with three locales (FR, EN, ES) and default set to ES:

  ```bash
  ./create_next_i18n_pwa.sh \
    -n my-app-pwa \
    -a "John Doe" \
    -l "fr,en,es" \
    -D es \
    -p
  ```

---

## Expected Project Structure

After running the script, your new project folder will look like this:

```
my-app/                  # Root project directory
├── locales/             # Translation JSON files
│   ├── fr/common.json
│   └── en/common.json
├── node_modules/        # Installed dependencies
├── public/              # Static files (includes manifest.json if -p)
├── src/                 # Source code (pages, components, styles)
│   ├── components/
│   ├── pages/
│   └── styles/
├── .eslintrc.json       # ESLint configuration
├── .prettierrc          # Prettier configuration
├── LICENSE              # MIT license file
├── next.config.js       # Next.js configuration (i18n + PWA if enabled)
├── package.json         # Project metadata and scripts
└── tailwind.config.js   # Tailwind CSS configuration
```

---

## Running Your Application

```bash
cd my-app
npm install       # Install dependencies
npm run dev       # Start development server
```

Open your browser at **[http://localhost:3000](http://localhost:3000)** to see your Next.js app in action.

---

## Contributing

Pull requests, issues, and suggestions are welcome!
Please open an issue or a pull request on the GitHub repository.
