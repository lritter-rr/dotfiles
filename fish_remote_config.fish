# This script is designed for single-run execution via:
# curl -sS -o /tmp/remote_config.fish YOUR_RAW_FISH_CONFIG_URL
# source /tmp/remote_config.fish

echo "--- Starting Remote Fish Configuration Setup ---"
echo ""

# 🐠 Oh My Fish (OMF) Setup
# --------------------------------------------------------

# Define the expected OMF data directory explicitly
set -l OMF_DATA_DIR "$HOME/.local/share/omf"
set -l OMF_CONFIG_DIR "$HOME/.config/omf"
set -l config_file "$HOME/.config/fish/config.fish"

# Check if the Oh My Fish directory exists
if not test -d "$OMF_DATA_DIR"
    echo "Oh My Fish not found. Attempting manual installation with explicit paths..."
    
    if command -q git
        set -l temp_omf_dir "/tmp/oh-my-fish-temp"
        set -l omf_install_bin "$temp_omf_dir/bin/install"

        # 1. Clone the repository to a temporary location
        echo "Cloning OMF repository to $temp_omf_dir..."
        git clone https://github.com/oh-my-fish/oh-my-fish $temp_omf_dir 2>/dev/null

        if test -d $temp_omf_dir
            # 2. Run the install script from the cloned repo with explicit environment variables
            echo "Running OMF install script..."
            env OMF_CONFIG="$OMF_CONFIG_DIR" fish $omf_install_bin
            
            # 3. Clean up the temporary clone directory
            rm -rf $temp_omf_dir
            
            echo "Oh My Fish installation initiated. Run this setup command again to apply the theme and config."
        else
            echo "Error: Failed to clone the OMF repository."
        end
    else
        echo "Error: 'git' command not found. Cannot install Oh My Fish."
    end
    
else
    # --- (OMF Found Block - PERSISTENCE FIX APPLIED HERE) ---
    echo "Oh My Fish found at $OMF_DATA_DIR. Ensuring theme persistence."
    
    # Source OMF init script to make 'omf' command available
    set -l omf_init_path "$OMF_DATA_DIR/init.fish"
    if test -f "$omf_init_path"
        source "$omf_init_path"
    else
        echo "Warning: OMF init file not found at $omf_init_path."
    end
    
    # Install theme (needed if it was deleted, harmless if present)
    echo "Installing 'bobthefish' theme..."
    omf install bobthefish 2>/dev/null
    
    # --- CRITICAL PERSISTENCE FIX: Write activation commands to config.fish ---
    echo "Writing theme activation commands to $config_file..."
    set -l config_updated false
    
    # Define ALL theme commands in a single array
    set -l theme_commands (
        "omf theme bobthefish"
        "set -g theme_nerd_fonts yes"
        "set -g theme_color_scheme nord"
        "set -g theme_show_project_parent no"
        "set -g theme_display_user no"  
        "set -g theme_display_hostname no"
        "set -g theme_display_ruby no"
    )
    
    # Loop through the list of commands
    for command_to_add in $theme_commands
        # Use grep -qF to quickly check if the exact command line exists in the config file
        if not grep -qF "$command_to_add" "$config_file"
            echo "$command_to_add" >> "$config_file"
            set config_updated true
        end
    end
    
    if $config_updated
        echo "Theme configurations added to config.fish."
    else
        echo "Theme configurations already present in config.fish."
    end
    
    # Source config.fish to apply these new changes immediately to the current session
    source "$config_file"
    echo "OMF configuration reloaded."
    
    end

# --------------------------------------------------------
# 💻 Lazygit Setup
# --------------------------------------------------------

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

# --------------------------------------------------------
# 🛠️ Fish Alias & Git Configuration
# --------------------------------------------------------

echo "--- Fish Alias & Git Configuration Setup ---"

# 1. Add the persistent fish alias
echo "Setting persistent fish alias: gitcommands -> 'git config --list --show-origin'"

# FIXED: Direct config.fish write for alias persistence
set -l alias_definition "alias gitcommands='git config --list --show-origin'"

# Check if the alias already exists in the config file before appending
if not grep -qF "$alias_definition" "$config_file" 
    echo $alias_definition >> "$config_file"
    echo "Alias added to config.fish for persistence."
    set config_updated true
else
    echo "Alias already exists in config.fish."
end


# 2. Apply all Git configuration settings using `git config --global`

# Core settings
git config --global core.editor 'code --wait'
git config --global pull.rebase false 
git config --global merge.conflictstyle diff3
git config --global rebase.instructionFormat '"(%an <%ae>) %s"'

# Credential helper
git config --global credential.helper '/usr/bin/gp credential-helper'

# LFS filter
git config --global filter.lfs.clean 'git-lfs clean -- %f'
git config --global filter.lfs.smudge 'git-lfs smudge -- %f'
git config --global filter.lfs.process 'git-lfs filter-process'
git config --global filter.lfs.required true

# Push and Help
git config --global push.default simple
git config --global help.autocorrect 20

# Aliases
git config --global alias.fixup '!git add . && git commit --fixup=${1:-$(git rev-parse HEAD)} && GIT_EDITOR=true git rebase --interactive --autosquash ${1:-$(git rev-parse HEAD~2)}~1'
git config --global alias.fileschanged 'diff HEAD^ HEAD --name-only'
git config --global alias.fc 'diff --name-only HEAD~1 HEAD'
git config --global alias.to 'commit -a --amend --no-edit'
git config --global alias.tackon 'commit -a --amend --no-edit'
git config --global alias.st 'status'
git config --global alias.dt 'difftool HEAD^ HEAD --no-prompt'
git config --global alias.temp 'checkout temp'
git config --global alias.sd 'branch --delete'
git config --global alias.safedelete 'branch --delete'
git config --global alias.sami 'clean -dn'
git config --global alias.druggedfox 'clean -df'
git config --global alias.morning 'commit -a'
git config --global alias.remessage 'commit --amend'
git config --global alias.rip '!git reset HEAD~1 $1' 
git config --global alias.ripout '!git reset HEAD~1 $1 && git checkout -- .'
git config --global alias.ro 'reset HEAD~1'
git config --global alias.nored 'checkout -- .'
git config --global alias.nogreen 'reset HEAD .'
git config --global alias.lg 'log --color --graph --pretty=format:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset --abbrev-commit'
git config --global alias.cane 'commit --amend --no-edit'
git config --global alias.cod 'checkout `git branch --contains HEAD --no-merged | head -1`'
git config --global alias.fcs 'diff --name-only'
git config --global alias.us 'submodule update --recursive --remote'
git config --global alias.updatesubmodules 'submodule update --recursive --remote'

echo "All Git configurations applied to $HOME/.gitconfig."

# 3. Source the config file if any change was made (resourcing the config.fish file)
if set -q config_updated
    echo "Sourcing updated config.fish to apply changes to the current session."
    source "$config_file"
    echo "Configuration reloaded."
end

echo ""
echo "🎉 Setup run complete!"