# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Add my zshFunctions repo to function patch search 
fpath=(
    ~/.config/zshFunctions
    ~/.config/zshFunctions/**/
    "${fpath[@]}"
)

# neovim alias 
alias -g vi=nvim
