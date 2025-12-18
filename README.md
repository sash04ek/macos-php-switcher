# PHP Version Manager for Homebrew

![License](https://img.shields.io/github/license/yourusername/php-version-manager) ![Bash](https://img.shields.io/badge/Language-Bash-4EAA25) ![macOS](https://img.shields.io/badge/Platform-macOS-000000) ![PHP Version](https://img.shields.io/badge/PHP-8.2-blue)

A **powerful Bash script** to manage multiple PHP versions via [Homebrew](https://brew.sh/) on macOS.  
Easily **switch PHP versions**, **stop services**, and **install missing versions** with colorful, interactive prompts.

---

## Features

- ✅ Show the **currently active PHP version**  
- ✅ List all **installed PHP versions**  
- ✅ **Switch PHP versions** with one command  
- ✅ **Stop all running PHP services**  
- ✅ Interactive prompts for installation or restarting services  
- ✅ Beautiful **color-coded output**

---

## Prerequisites

- macOS  
- [Homebrew](https://brew.sh/) (script can install it automatically if missing)  

---

## Installation

```bash
git clone https://github.com/yourusername/php-version-manager.git
cd php-version-manager
chmod +x php-manager.sh
sudo mv php-manager.sh /usr/local/bin/php-manager
