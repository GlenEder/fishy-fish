if status is-interactive
    # Commands to run in interactive sessions can go here
end

# OPTIONAL: uncomment if on MacOs when using homebrew
# add Homebrew to path 
# fish_add_path --path /opt/homebrew/bin


# Define enviroment paths  
set -gx FISH_HOME $HOME/.config/fish
set -gx DEVROOT $HOME/devroot
set -gx FISHY_FISH_HOME $DEVROOT/fishy-fish
set -gx FISHY_FISH_FUNCTIONS $DEVROOT/fishy-fish
set -gx NEOVIM_HOME $HOME/.config/nvim

# Add systems like Maki coding agent to path
set -gx PATH "/home/geder/.local/bin:$PATH"

# Load env secrets 
source $FISHY_FISH_HOME/env.fish

# add custom fish functions to function path (**/ expands functions/ plus every nested dir)
set -a fish_function_path $FISHY_FISH_HOME/functions/**/

# define neovim as editor of choice 
set -gx EDITOR nvim

# custom aliases 
abbr -a vi --position anywhere nvim

# OPTIONAL: comment out if not using starship 
starship init fish | source
