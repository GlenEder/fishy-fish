if status is-interactive
    # Commands to run in interactive sessions can go here
end

# add Homebrew to path 
fish_add_path --path /opt/homebrew/bin


# Define enviroment paths  
set -gx FISH_HOME $HOME/.config/fish
set -gx DEVROOT $HOME/devroot
set -gx FISHY_FISH_FUNCTIONS $DEVROOT/fishy-fish
set -gx NEOVIM_HOME $HOME/.config/nvim

# add custom fish functions to function path
set fish_function_path $fish_function_path $DEVROOT/fishy-fish/*/

# define neovim as editor of choice 
set -gx EDITOR nvim
# custom aliases 
abbr -a !! --position anywhere --function bang_bang
abbr -a vi --position anywhere nvim
