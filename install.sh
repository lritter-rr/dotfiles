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

echo "--- Lazygit Setup ---"

# 1. Check if lazygit is already installed and runnable
if command -q lazygit
    echo "Lazygit is already installed."
else
    echo "Lazygit not found. Attempting user-local installation..."
    
    # Ensure the local bin directory exists and is in the PATH
    set -l local_bin "$HOME/.local/bin"
    if not test -d "$local_bin"
        mkdir -p "$local_bin"
    end
    # Ensure this path is in the user's permanent path list
    if not contains "$local_bin" $fish_user_paths
        set -U fish_user_paths $fish_user_paths "$local_bin"
        echo "Added $local_bin to your PATH for persistence."
    end

    echo "Fetching latest Lazygit version..."
    set LAZYGIT_VERSION (curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -oP '"tag_name": "v\K[^"]*')
    
    if test -z "$LAZYGIT_VERSION"
        echo "Error: Could not determine latest Lazygit version. Installation aborted."
    else
        echo "Found version: v$LAZYGIT_VERSION"
        set -l LAZYGIT_DOWNLOAD_URL "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/lazygit_"$LAZYGIT_VERSION"_Linux_x86_64.tar.gz"
        
        # 2. Download the tarball to a temporary location using -o
        echo "Downloading Lazygit..."
        curl -Lo /tmp/lazygit.tar.gz "$LAZYGIT_DOWNLOAD_URL"
        
        # 3. Extract the binary
        echo "Extracting binary..."
        tar -xzf /tmp/lazygit.tar.gz -C /tmp
        
        # 4. Install the binary to the local bin path
        if test -f /tmp/lazygit
            install /tmp/lazygit "$local_bin"
            echo "Lazygit installed successfully to $local_bin/lazygit"
        else
            echo "Error: Lazygit binary not found after extraction."
        end

        # 5. Clean up
        rm /tmp/lazygit.tar.gz /tmp/lazygit 2>/dev/null
    end
end

echo "🎉 Setup complete!"