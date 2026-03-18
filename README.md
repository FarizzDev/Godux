# Godux: Godot Universal Export 🚀

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![Version](https://img.shields.io/github/v/release/FarizzDev/Godux) ![Godot](https://img.shields.io/badge/Godot-3.x%20%7C%204.x-blue) ![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android-lightgrey.svg)

_**Crack The Limit and Go Beyond It.**_

---

Godux is a free and open-source command-line tool that uses GitHub Actions to export your Godot Engine projects.

Whether you're on a mobile phone or a low-spec machine, Godux runs the entire export process on GitHub's servers. So your device just needs a terminal.

## ✨ Features

- 🌍 **Cross-Platform:** Export for Windows, Linux, macOS, Android, and HTML5, from any device.
- ☁️ **Cloud Builds:** GitHub's servers handle everything, so your machine stays free.
- 🔒 **Keystore Management:** Android keystore credentials are stored as GitHub Secrets.
- 📊 **Real-time Monitoring:** Watch your build progress step-by-step from the terminal.

## ⚙️ How It Works

1. Run `gdx` from your project directory.
2. Godux pushes your project to a private GitHub repository.
3. A GitHub Actions workflow downloads Godot and runs the export.
4. The result is packaged into a `.zip` and attached to a GitHub Release.
5. Godux notifies you and prompts you to download.

---

## 🚀 Getting Started

### 1. Prerequisites

- A [GitHub account](https://github.com).
- A bash shell, like Termux on Android, or the default terminal on Linux/macOS.

### 2. Installation

```bash
# Using curl
curl -fsSL https://github.com/FarizzDev/Godux/releases/latest/download/install.sh | bash

# Using wget
wget -qO- https://github.com/FarizzDev/Godux/releases/latest/download/install.sh | bash
```

This installs `gdx` as a global command.

### 3. Exporting

Run `gdx` from your Godot project's root directory:

```bash
gdx
```

The first time, you'll go through a quick one-time setup:

- Enter your name and email for Git commits.
- Log in to GitHub via the CLI.
- Godux creates a private repository for your project automatically.

Then the export flow:

1. **Select a preset** from the interactive menu.
2. **Enter Godot links** or press `Enter` for the default (3.6-stable). Other versions can be found on the [godot-builds releases page](https://github.com/godotengine/godot-builds/releases).
3. **Android keystore** — if exporting for Android, follow the prompts to set up signing.
4. Watch the build, then download the result to `export/`.

> **Note:** Godot 3 requires the headless build (`linux_headless.64`). Godot 4 requires the standard Linux build (`linux.x86_64`).

## 🤝 Contributing

PRs are welcome! To contribute:

1. Fork the repository.
2. Create a branch (`git checkout -b fix/add-bug-sprayer`).
3. Commit your changes (`git commit -m 'fix: delete some bugs'`).
4. Push and open a Pull Request.

## 🐛 Reporting Bugs

Open an [Issue](https://github.com/FarizzDev/Godux/issues) and include:

- Steps to reproduce.
- Relevant logs or error messages.
- Your OS and environment.

## 📜 License

[MIT](LICENSE)
