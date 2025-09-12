# Godux: Godot Universal eXport 🚀

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![Godot Version](https://img.shields.io/badge/Godot-3.x-blue.svg) ![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android-lightgrey.svg)

**Export Godot Projects From Anywhere, To Anywhere.**

---

Godux is a powerful command-line tool that leverages GitHub Actions to build and export your Godot Engine projects. It empowers developers to trigger builds from any device—be it a desktop, laptop, or even an Android phone—and export for any platform Godot supports.

Ever needed to compile a Windows `.exe` from your Linux machine or build an Android `.apk` from your phone? Godux makes this a reality.

> **Note:** Currently, Godux officially supports **Godot 3.x**. Support for **Godot 4.x** is coming soon!

## ✨ Core Features

- 🌍 **Universal Workflow:** Initiate builds from any development environment and export for Windows, Linux, macOS, Android, or HTML5.
- ☁️ **Cloud-Powered Builds:** All compilation is handled by GitHub's powerful servers, freeing up your local machine's resources.
- 🤖 **Automated Setup:** A guided CLI experience helps you with the one-time setup of your Git and GitHub credentials.
- 🔒 **Secure Keystore Management:** For Android builds, your keystore credentials are automatically managed as secure GitHub Secrets.
- 📊 **Real-time Monitoring:** Track the progress of your builds directly from your terminal.

## 🤔 Why Godux?

Developing a game often involves multiple platforms. You might write code on a Windows desktop, test on a Linux laptop, and need to send a build to a tester on macOS. Furthermore, while the Godot Mobile editor is great for development on the go, it lacks a built-in export function.

Godux was created to solve these problems. By offloading the export process to the cloud, it provides a single, consistent workflow to build your game for any target, from any machine.

## ⚙️ How It Works

Godux combines the power of shell scripting and CI/CD to create a seamless workflow:

1.  **Trigger:** You run the `gdx` command from your device's terminal.
2.  **Push:** The script commits and pushes your project files to a private GitHub repository.
3.  **Automate:** This push triggers a pre-configured GitHub Actions workflow (`export.yml`).
4.  **Build:** The GitHub Actions runner spins up a virtual machine, downloads the specified Godot version, and runs the export command for your chosen platform.
5.  **Download:** Once the build is complete, the script notifies you and allows you to download the resulting artifact (e.g., `.apk`, `.zip`) directly to your device.

---

## 🚀 Getting Started

Getting up and running with Godux is simple.

### 1. Prerequisites

- A **GitHub Account** (if you don't have one, [create one here](https://github.com)).
- A standard **bash shell environment** (like Termux on Android, or the default terminal on Linux/macOS).

### 2. Installation & Setup

The setup process is designed to be a one-time affair.

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/FarizzDev/Godux.git
    cd Godux
    ```

2.  **Run the setup script:**

    ```bash
    bash setup.sh
    ```

    This script will automatically detect your operating system, install all the required dependencies (`git`, `gh`, `fzf`, `bc`, `jq`), and install `gdx` as a global command on your system.

3.  **First-Time Configuration:**
    The first time you run the `gdx` command, it will guide you through a one-time setup process:
    - **Git Configuration:** If you haven't configured Git before, you will be prompted to enter your name and email.
    - **GitHub Authentication:** The script will then prompt you to log in to GitHub. This is required to create repositories and manage secrets for you.
    - **Repository Creation:** The script will automatically create a new **private** repository on your GitHub account to host your project and run the build workflows.

### 3. The Export Workflow

Once the installation is complete, you can export your project from anywhere by running:

```bash
gdx
```

The tool will then guide you through the following steps:

1.  **Select a Platform:** Use the interactive menu to choose your target platform.
2.  **Provide Links (Optional):** You can press `Enter` to use the default Godot and template versions or provide custom download links.
3.  **Android Keystore (If applicable):** If you chose `Android`, you will be asked for a `user` alias and a `pass` for the keystore. This is stored securely in your repository's GitHub Secrets.
4.  **Monitor the Build:** The script will show you the real-time progress of the build.
5.  **Download:** Once finished, you will be prompted to download the exported artifact. The file will be saved into the `export/` directory.

## 🤝 Contributing

Contributions are always welcome! Whether it's a new feature, a bug fix, or documentation improvements, we appreciate your help.

Please follow these steps to contribute:

1.  **Fork** the repository.
2.  Create a new branch (`git checkout -b feature/YourAmazingFeature`).
3.  Make your changes and commit them (`git commit -m 'Add some AmazingFeature'`).
4.  Push to your branch (`git push origin feature/YourAmazingFeature`).
5.  Open a **Pull Request**.

## 🐛 Reporting Bugs

If you encounter a bug or have a problem, please open an **Issue** on the [GitHub repository](https://github.com/FarizzDev/Godux/issues).

When filing an issue, please include as much detail as possible:
- A clear and descriptive title.
- Steps to reproduce the bug.
- Any relevant logs or error messages.
- Your operating system and environment.

This will help us resolve the issue much faster.

## 📜 License

This project is licensed under the [MIT License](LICENSE).