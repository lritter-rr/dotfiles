#!/bin/bash
set -e

echo "🚀 Starting Coder workspace dotfiles installation..."

# --------------------------------------------------------
# 1. Prepare .config directory
# --------------------------------------------------------
echo "📦 Copying configuration files..."
mkdir -p "$HOME/.config/omf"
if [ -d ".config" ]; then
  cp -a .config/. "$HOME/.config/"
  echo "✅ Copied .config directory"
fi

# --------------------------------------------------------
# 2. Setup Fish Shell
# --------------------------------------------------------
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
FISH_PATH=$(command -v fish)

if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
  echo "🔧 Attempting to change shell to fish..."
  # Use sudo -n (non-interactive) to fail gracefully if a password is required
  if ! grep -q "$FISH_PATH" /etc/shells; then
    sudo tee -a /etc/shells <<< "$FISH_PATH"
  fi
  sudo chsh -s "$FISH_PATH" "$USER" || echo "⚠️ Could not change shell automatically. Please run 'chsh -s $(which fish)' manually."
else
  echo "✅ Fish is already the default shell."
fi

# --------------------------------------------------------
# 3. Install Oh My Fish (only if not already installed)
# --------------------------------------------------------
if [ ! -f "$HOME/.local/share/omf/init.fish" ]; then
  echo "🔧 Installing Oh My Fish..."
  curl -s https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install_omf
  fish install_omf --path=~/.local/share/omf --config=~/.config/omf --noninteractive
  rm install_omf
  echo "✅ Oh My Fish installed successfully."
else
  echo "✅ Oh My Fish is already installed. Skipping installation."
  # Force a reload/install of the theme
  fish -c "omf install lambda"
  fish -c "omf reload"
fi

# --------------------------------------------------------
# 4. Lazygit Setup (Translated to Bash)
# --------------------------------------------------------

echo "--- Lazygit Setup ---"

# Check if lazygit is already installed
if command -v lazygit &> /dev/null; then
    echo "Lazygit is already installed."
else
    echo "Lazygit not found. Attempting user-local installation..."
    
    # Ensure the local bin directory exists
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"

    # Add to Fish path permanently (since you are using Fish)
    # We run this via fish -c because we are currently in bash
    if command -v fish &> /dev/null; then
        fish -c "if not contains \"$LOCAL_BIN\" \$fish_user_paths; set -U fish_user_paths \$fish_user_paths \"$LOCAL_BIN\"; end"
        echo "Added $LOCAL_BIN to your Fish PATH for persistence."
    fi

    echo "Fetching latest Lazygit version..."
    # Bash syntax for command substitution is $() not ()
    # grep -P might not be available on all minimal distros, so we use standard sed/awk if possible, 
    # but assuming your environment has grep -P based on your snippet:
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -oP '"tag_name": "v\K[^"]*')
    
    if [ -z "$LAZYGIT_VERSION" ]; then
        echo "Error: Could not determine latest Lazygit version. Installation aborted."
    else
        echo "Found version: v$LAZYGIT_VERSION"
        LAZYGIT_DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        
        # Download the tarball
        echo "Downloading Lazygit..."
        curl -Lo /tmp/lazygit.tar.gz "$LAZYGIT_DOWNLOAD_URL"
        
        # Extract the binary
        echo "Extracting binary..."
        tar -xzf /tmp/lazygit.tar.gz -C /tmp
        
        # Install the binary to the local bin path
        if [ -f /tmp/lazygit ]; then
            install /tmp/lazygit "$LOCAL_BIN"
            echo "Lazygit installed successfully to $LOCAL_BIN/lazygit"
        else
            echo "Error: Lazygit binary not found after extraction."
        fi

        # Clean up
        rm /tmp/lazygit.tar.gz /tmp/lazygit 2>/dev/null
    fi
fi

echo "🎉 Setup complete!"