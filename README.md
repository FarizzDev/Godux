# Godux: Godot Universal Export 🚀

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![Godot Version](https://img.shields.io/badge/Godot-3.x-blue.svg) ![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android-lightgrey.svg)

_**Crack The Limit and Go Beyond It.**_

---

Godux is a free and open-source command-line tool that leverages GitHub Actions
to build and export your Godot Engine projects — from any device.

No PC? No problem. Whether you're on a mobile phone, tablet, or a low-spec
machine, Godux offloads the entire export process to GitHub's servers — so
you can ship your game from any device.

> **Note:** Currently, Godux officially supports **Godot 3.x**. Support for **Godot 4.x** is coming soon!

## ✨ Core Features

- 🌍 **Cross-Platform Exports:** Initiate builds from any development environment and export for Windows, Linux, macOS, Android, or HTML5.
- ☁️ **Cloud-Powered Builds:** All compilation is handled by GitHub's powerful servers, freeing up your local machine's resources.
- 🔒 **Secure Keystore Management:** For Android builds, your keystore credentials are automatically managed as secure GitHub Secrets.
- 📊 **Real-time Monitoring:** Track the progress of your builds directly from your terminal.

## 🤔 Why Godux?

The primary purpose of Godux is to overcome hardware and environment limitations. It is especially useful when:

- **You are developing on a device that cannot run the standard Godot export process,** such as a mobile phone or a tablet. Godux allows you to trigger a full-featured export workflow directly from a simple shell environment.
- **Your development machine has limited resources.** Compiling projects, particularly for multiple platforms, can be slow and consume significant CPU and RAM. Godux offloads this entire process to GitHub's powerful servers, keeping your machine responsive.

## ⚙️ How It Works

Godux combines the power of shell scripting and CI/CD to create a seamless workflow:

1.  **Trigger:** You run the `gdx` command from your device's terminal.
2.  **Push:** The script commits and pushes your project files to a private GitHub repository.
3.  **Automate:** This push triggers a pre-configured GitHub Actions workflow (`export.yml`).
4.  **Build:** The GitHub Actions runner spins up a virtual machine, downloads the specified Godot version, and runs the export command for your chosen platform.
5.  **Download:** Once the build is complete, the workflow packages the output into a `.zip` file and attaches it to a new GitHub Release. The `gdx` script then notifies you and prompts you to download this release.

---

## 🚀 Getting Started

### 1. Prerequisites

- A **GitHub Account** (if you don't have one, [create one here](https://github.com)).
- A standard **bash shell environment** (like Termux on Android, or the default terminal on Linux/macOS).

### 2. Installation

Run this command to install Godux:

```bash
curl -fsSL https://github.com/FarizzDev/Godux/releases/latest/download/install.sh | bash
```

This will install `gdx` as a global command. Dependencies will be automatically installed when you first run `gdx`.

### 3. Exporting

Run `gdx` from your Godot project's root directory:

```bash
gdx
```

The first time you run it, Godux will guide you through a one-time setup:

- **Git Configuration:** Enter your name and email for Git commits.
- **GitHub Authentication:** Log in to GitHub via the CLI.
- **Repository Setup:** A private GitHub repository will be automatically created for your project.

After setup, Godux will walk you through the export process:

1. **Select a Preset:** Choose your target platform from an interactive menu.
2. **Provide Links (Optional):** Press `Enter` to use the default Godot 3.6-stable, or provide a custom download link.
3. **Android Keystore (if applicable):** Provide a `user` alias and `pass` for your keystore. Credentials are stored securely as GitHub Secrets.
4. **Monitor the Build:** Watch real-time build progress from your terminal.
5. **Download:** Once complete, you'll be prompted to download the result. Files are saved to the `export/` directory.

## 🤝 Contributing

Contributions are always welcome! Whether it's a new feature, a bug fix, or documentation improvements, we appreciate your help.

Please follow these steps to contribute:

1.  **Fork** the repository.
2.  Create a new branch (`git checkout -b fix/add-bug-sprayer`).
3.  Make your changes and commit them (`git commit -m 'fix: delete some bugs'`).
4.  Push to your branch (`git push origin fix/add-bug-sprayer`).
5.  Open a **Pull Request**.

## 🐛 Reporting Bugs

Your feedback is invaluable for improving Godux. If you encounter a bug or have a problem, please do not hesitate to open an **Issue** on the [GitHub repository](https://github.com/FarizzDev/Godux/issues).

When filing an issue, please include as much detail as possible:

- A clear and descriptive title.
- Steps to reproduce the bug.
- Any relevant logs or error messages.
- Your operating system and environment.

This will help us resolve the issue much faster.

## 📜 License

This project is licensed under the [MIT License](LICENSE).
