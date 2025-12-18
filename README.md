# 🚀 PHP Version Manager for Homebrew

![License](https://img.shields.io/github/license/yourusername/php-version-manager) ![Bash](https://img.shields.io/badge/Language-Bash-4EAA25) ![macOS](https://img.shields.io/badge/Platform-macOS-000000) ![PHP Version](https://img.shields.io/badge/PHP-8.2-blue)

A **powerful Bash script** to manage multiple PHP versions via [Homebrew](https://brew.sh/) on macOS.  
Easily **switch PHP versions**, **stop services**, and **install missing versions** with colorful, interactive prompts.

---

## ✨ Features

- ✅ Show the **currently active PHP version**  
- ✅ List all **installed PHP versions**  
- ✅ **Switch PHP versions** with one command  
- ✅ **Stop all running PHP services**  
- ✅ Interactive prompts for installation or restarting services  
- ✅ Beautiful **color-coded output**

---

## 🖥 Prerequisites

- macOS  
- [Homebrew](https://brew.sh/) (script can install it automatically if missing)  

---

## ⚡ Installation

```bash
git clone https://github.com/sash04ek/macos-php-switcher.git
cd macos-php-switcher
chmod +x sphp.sh
sudo mv sphp.sh /usr/local/bin/sphp
```

---

## 🛠 Usage

Show current PHP version and installed versions
```bash
sphp
```

Example output:
```text
Current PHP version: 8.2.3
Installed PHP versions:
  - php (8.2.3)
  - php@8.1 (8.1.20)
  - php@8.0 (8.0.28)

Usage:
  php-manager <version>   Switch PHP version (e.g. 8.2)
  php-manager stop        Stop all PHP services
```

Switch PHP version
```bash
sphp 8.1
```

Example output:
```text
Activating PHP 8.1...
PHP 8.1.20
✅ PHP 8.1 activated
```

Stop all PHP services
```bash
sphp stop
```

Example output:
```text
Stopping all PHP services...
All PHP services have been stopped.
```

---

## 🎛 Interactive Prompts

- Install missing Homebrew if needed
- Install missing PHP versions on demand
- Restart already active PHP version if requested

---

## 🎨 Colors in Output

- Blue – Info
- Green – Success
- Yellow – Warning
- Red – Error

---

## 📝 Notes

- Uses Homebrew services to run PHP in the background
- Works best with PHP installed via Homebrew (php, php@8.1, php@8.0, etc.)
- Fully interactive and user-friendly

---

## 📄 License

MIT License © sash04ek

