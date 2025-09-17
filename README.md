
# Git Manager for Windows 🚀

![Git Logo](https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png)

**Supercharge your Git experience on Windows with these handy scripts!** Whether you're setting up Git for the first time, keeping it fresh, or saying goodbye, we've got you covered. No more fumbling with installers – just run a script and boom! 💥

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)]()

## 🌟 Features

- **Easy Installation**: Two ways to install Git – via Winget or direct download from GitHub.
- **Seamless Updates**: Keep Git up-to-date with a single command.
- **Clean Uninstall**: Remove Git completely from common installation paths (admin required).
- **User-Friendly**: Scripts handle checks, configurations, and cleanups automatically.
- **Custom Configurations**: Sets optimal Git settings for Windows, like CRLF handling and performance tweaks.
- **Additional Tools**: Handy utilities for managing multiple Git repositories and configurations.

## 📋 Requirements

- Windows 10 or later
- PowerShell (for some download methods)
- Administrator privileges for uninstallation

## 🔧 Usage

Download the scripts and run them from Command Prompt or PowerShell. Make sure to run as a regular user unless specified.

### 1. Install Git via Winget
```cmd
install_git_winget.cmd
```
- Checks if Winget is available.
- Installs Git silently for the current user.
- Configures global Git settings (e.g., default branch to main, CRLF handling).

### 2. Install Git via Direct Download
```cmd
install_git.cmd
```
- Downloads the latest Git installer (v2.50.1 – update the script for newer versions).
- Installs to `%LOCALAPPDATA%\Programs\Git` with predefined options (Vim as editor, OpenSSH, etc.).
- Handles downloads via curl, PowerShell, or bitsadmin.

### 3. Update Git
```cmd
update_git.cmd
```
- Uses Git's built-in updater to fetch and install the latest version.
- Run as a regular user.

### 4. Uninstall Git
```cmd
uninstall_git.cmd
```
- **Requires Administrator privileges** (right-click and run as admin).
- Searches common paths like `%ProgramFiles%\Git`, `%LOCALAPPDATA%\Programs\Git`.
- Runs the uninstaller silently and cleans up remaining files.

## 🛠️ Additional Tools

The `Tools` folder contains helpful utilities for managing Git repositories and configurations:

### Repository Management Tools

#### Bulk Operations for Multiple Repositories
```cmd
Tools\git_pull_all.cmd
```
- Automatically finds all Git repositories in the current directory.
- Runs `git pull` on each repository to fetch the latest changes.
- Perfect for keeping multiple projects up-to-date at once.

```cmd
Tools\git_push_all.cmd
```
- Finds all Git repositories in the current directory.
- Prompts for a commit message.
- Stages all changes (`git add .`), commits with your message, and pushes to remote.
- Great for quickly committing and pushing changes across multiple projects.

```cmd
Tools\git_gc_all.cmd
```
- Runs garbage collection (`git gc`) on all repositories in the current directory.
- Optimizes repository size and performance by cleaning up unnecessary files.
- Useful for maintaining repository health across multiple projects.

### Configuration Tools

#### User Details Setup
```cmd
Tools\git_set_details.cmd
```
- Prompts for your Git username and email address.
- Sets global Git configuration (`git config --global user.name` and `user.email`).
- Essential for ensuring your commits are properly attributed.

#### Line Ending Configuration
```cmd
Tools\set_git_crlf.cmd
```
- Sets Git to use CRLF (Windows-style) line endings.
- Configures `core.autocrlf=true` and `core.eol=crlf`.
- Recommended for Windows-only development environments.

```cmd
Tools\set_git_lf.cmd
```
- Sets Git to use LF (Unix/Linux-style) line endings.
- Configures `core.autocrlf=false` and `core.eol=lf`.
- Recommended for cross-platform development or when working with Unix/Linux systems.

### Usage Tips
- Run the bulk operation tools from a parent directory containing multiple Git repositories.
- All tools include built-in Git installation checks and error handling.
- Tools automatically skip non-Git directories when scanning for repositories.

## ⚙️ Configuration Details

During installation, the scripts set these global Git configs for a smooth Windows experience:
- Default branch: `main`
- Line endings: CRLF
- Editor: Vim
- Credential helper: manager
- Performance: FSCache and preloadindex enabled
- And more! Check the scripts for full details.

## 🤝 Contributing

Feel free to fork, improve, and submit pull requests! If you find bugs or have ideas, open an issue.

## 📜 License

This project is licensed under the CRL License - see the [LICENSE.md](LICENSE.md) file for details.
