# 󰏖 PluginCraft • Omarchy Centralized Plugin Launcher Hub

> **Unified plugin manager and top-bar consolidation hub for Omarchy 4.0.2+.**

Author: **Ozan Özdil (ozdil)**  
License: **MIT**

---

## ✨ Features

- 󰏖 **Bar De-cluttering:** Consolidates all installed plugins into a single, elegant bar widget.
- 🚀 **1-Click Launch Hub:** Instant access to all plugin dashboards, scanners, and studios.
- 🔍 **Auto-Discovery:** Automatically scans `~/.config/omarchy/plugins/` and reads manifests.
- 🔒 **Zero Hardcoded Paths:** Dynamic plugin-relative execution.

---

## 🚀 Installation & Removal

### Installation
```bash
git clone https://github.com/ozdil/omarchy-plugin-craft.git ~/.config/omarchy/plugins/plugin-craft
chmod +x ~/.config/omarchy/plugins/plugin-craft/plugincraft-*
```

### Removal
```bash
rm -rf ~/.config/omarchy/plugins/plugin-craft
omarchy-restart-shell
```
