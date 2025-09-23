# Godux: Godot Universal eXport 🚀

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![Godot Version](https://img.shields.io/badge/Godot-3.x-blue.svg) ![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android-lightgrey.svg)

**Export Godot Projects From Anywhere, To Anywhere.**

---

Godux is a free and open-source command-line utility that leverages GitHub Actions to build and export Godot Engine projects.

For instance, one could export a project for Windows (.exe), Linux (.x86_64), and Android (.apk/.aab) directly from a mobile device.

> **Note:** Currently, Godux officially supports **Godot 3.x**. Support for **Godot 4.x** is coming soon!

## ✨ Core Features

- 🌍 **Cross-Platform Exports:** Initiate builds from any development environment and export for Windows, Linux, macOS, Android, or HTML5.
- ☁️ **Cloud-Powered Builds:** All compilation is handled by GitHub's powerful servers, freeing up your local machine's resources.
- 🔒 **Secure Keystore Management:** For Android builds, your keystore credentials are automatically managed as secure GitHub Secrets.
- 📊 **Real-time Monitoring:** Track the progress of your builds directly from your terminal.

## 🤔 Why Godux?

The primary purpose of Godux is to overcome hardware and environment limitations. It is especially useful when:

- **Your development machine has limited resources.** Compiling projects, particularly for multiple platforms, can be slow and consume significant CPU and RAM. Godux offloads this entire process to GitHub's powerful servers, keeping your machine responsive.
- **You are developing on a device that cannot run the standard Godot export process,** such as a mobile phone or a tablet. Godux allows you to trigger a full-featured export workflow directly from a simple shell environment.

## ⚙️ How It Works

Godux combines the power of shell scripting and CI/CD to create a seamless workflow:

1.  **Trigger:** You run the `gdx` command from your device's terminal.
2.  **Push:** The script commits and pushes your project files to a private GitHub repository.
3.  **Automate:** This push triggers a pre-configured GitHub Actions workflow (`export.yml`).
4.  **Build:** The GitHub Actions runner spins up a virtual machine, downloads the specified Godot version, and runs the export command for your chosen platform.
5.  **Download:** Once the build is complete, the workflow packages the output into a `.zip` file and attaches it to a new GitHub Release. The `gdx` script then notifies you and prompts you to download this release.

---

## 🚀 Getting Started

Getting up and running with Godux is simple.

### 1. Prerequisites

- A **GitHub Account** (if you don't have one, [create one here](https://github.com)).
- A standard **bash shell environment** (like Termux on Android, or the default terminal on Linux/macOS).

### 2. Installation & Setup

The setup process only needs to be done once.

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/FarizzDev/Godux
    cd Godux
    ```

2.  **Run the installation script:**

    ```bash
    bash install.sh
    ```

    This script will automatically detect your operating system, install all the required dependencies (`git`, `gh`, `fzf`, `bc`, `jq`), and install `gdx` as a global command on your system.

3.  **First-Time Configuration:**
    The first time you run the gdx command, it will guide you through the setup process: - **Git Configuration:** If you haven't configured Git before, you will be prompted to enter your name and email. - **GitHub Authentication:** The script will then prompt you to log in to GitHub. This is required to create repositories and manage secrets for you. - **Repository Creation:** The script will automatically create a new **private** repository on your GitHub account to host your project and run the build workflows.

### 3. Exporting

Once the installation is complete, you can export your project by running the following command from your project's root directory:

```bash
gdx
```

The tool will then guide you through the following steps:

1.  **Select a Platform:** Use the interactive menu to choose your target platform.
2.  **Provide Links (Optional):** You can press `Enter` to use the default Godot and template versions or provide custom download links. For example, you can find various versions on the [community-maintained `godot-builds` repository releases page](https://github.com/godotengine/godot-builds/releases).
3.  **Android Keystore (If applicable):** If you chose `Android`, you will be asked for a `user` alias and a `pass` for the keystore. This is stored securely in your repository's GitHub Secrets.
4.  **Monitor the Build:** The script will show you the real-time progress of the build.
5.  **Download:** Once finished, you will be prompted to download the release asset (a .zip file). The downloaded contents will be saved into the `export/` directory.

## 🤝 Contributing

Contributions are always welcome! Whether it's a new feature, a bug fix, or documentation improvements, we appreciate your help.

Please follow these steps to contribute:

1.  **Fork** the repository.
2.  Create a new branch (`git checkout -b feature/YourAmazingFeature`).
3.  Make your changes and commit them (`git commit -m 'feat: Add some amazing feature'`).
4.  Push to your branch (`git push origin feature/YourAmazingFeature`).
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
