#!/bin/bash
set -e

echo "🚀 Starting Coder workspace dotfiles installation..."

# 1. Prepare .config directory
echo "📦 Copying configuration files..."
mkdir -p "$HOME/.config/omf"
if [ -d ".config" ]; then
  cp -a .config/. "$HOME/.config/"
  echo "✅ Copied .config directory"
fi

# 2. Configure the OMF Bundle
# This tells OMF exactly what to install as soon as it starts
echo "plus lolfish" > "$HOME/.config/omf/bundle"
echo "✨ Added lolfish to OMF bundle"

# 3. Setup Fish Shell
if ! grep -q "$(command -v fish)" /etc/shells; then
  command -v fish | sudo tee -a /etc/shells
fi
chsh -s "$(command -v fish)"
echo "🐟 Fish shell set as default shell."

# 4. Install Oh My Fish (only if not already installed)
if [ ! -f "$HOME/.local/share/omf/init.fish" ]; then
  echo "🔧 Installing Oh My Fish..."
  curl -s https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install_omf
  fish install_omf --path=~/.local/share/omf --config=~/.config/omf --noninteractive
  rm install_omf
else
  echo "✅ Oh My Fish is already installed. Skipping installation."
  # Even if OMF is installed, we can force a reload of the bundle
  fish -c "omf reload"
fi

# 5. Cleanup
rm install_omf
echo "🎉 Setup complete!"