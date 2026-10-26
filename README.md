# Fishy Fish Functions

My personal terminal settings along with the fish functions I use every day.

The functions were ported from [BashLib](https://github.com/GlenEder/BashLib), which is now deprecated in favor of this repo.

## Setup

Clone this repo wherever you please.
I prefer to put it under `~/devroot/`.

```sh
git clone git@github.com:GlenEder/fishy-fish.git ~/devroot/fishy-fish
```

Create the secrets file from the example and fill in the keys you need:

```sh
cp ~/devroot/fishy-fish/env.fish.example ~/devroot/fishy-fish/env.fish
```

Link `config.fish` into the fish config directory and restart the shell:

```sh
ln -s ~/devroot/fishy-fish/config.fish ~/.config/fish/config.fish
```

`config.fish` sets `FISHY_FISH_HOME`, loads `env.fish`, and adds `functions/**/` to `fish_function_path`.
Every function below is autoloaded from its file, so no extra setup is needed after adding one.

### Terminal

[iTerm2](https://iterm2.com/)

### Shell

[Fish](https://fishshell.com/)

### Font

[Lekton Nerd Font](https://www.nerdfonts.com/font-downloads)
Font size set to 20 cause I'm blind

### Editor

[Neovim](https://neovim.io/)
[My neovim configuration](https://github.com/GlenEder/nvim)

## Functions

### cd

| Function | Description |
|---|---|
| `cdc` | Go to `~/.config` |
| `cdf` | Go to this repo |
| `cdj` | Go to `$DEVROOT` |
| `cdn` | Go to `$DEVROOT/notes` |

### git

| Function | Description |
|---|---|
| `gits [-f/--filenames-only] [-h/--help]` | `git status -s`, or filenames only with `-f` |
| `dropChanges [-a/--all-files] [-d/--delete-untracked] [-h/--help]` | Revert changes; `-a` checks out every changed file, `-d` deletes untracked files (current dir only unless `-a`) |
| `main` | Check out the default branch, pull, fetch tags, then run `deleteOldBranches` |
| `createBranch <branch-name>` | Create a branch, push it, and set the upstream |
| `deleteOldBranches` | Delete local branches whose remote is gone, removing their worktrees first |
| `checkout` | Pick a local or remote branch from a paged list, then check it out and pull |
| `updateDevroot [-f/--fetch-only] [-i/--ignore-dir <dir>]... [directory]` | Update every git repo under `$DEVROOT` (or the given directory) in parallel |

`main` is destructive: it deletes stale branches and force-removes the worktrees that hold them.
`dropChanges -d` really deletes untracked files.

### utils

| Function | Description |
|---|---|
| `bang_bang` | Print the previous command |
| `configFishEnvs` | Open `$FISH_HOME/config.fish` in `$EDITOR` |
| `configFishFunctions` | Open this repo in `$EDITOR` |
| `configNeovim` | Open the neovim `init.lua` in `$EDITOR` |
| `confirmYN` | Prompt for a y/n answer |
| `editCronjobs` | Edit `/etc/crontab` and reload it |
| `getUserInput <prompt>` | Prompt for a line of input |
| `gr <pattern>` | `grep -rIni` |
| `isNumber <value>` | Return success when the value is all digits |
| `l` | `ls -lt` |
| `pwGen [-l/--length <n>] [-h/--help]` | Generate a random password (default length 32) |
| `srcFish` | Reload `~/.config/fish/config.fish` |

### logging

| Function | Description |
|---|---|
| `log_info [-t/--timestamp] <message>` | Print `INFO: <message>` to stdout |
| `log_warning [-t/--timestamp] <message>` | Print `WARN: <message>` to stderr |
| `log_error [-t/--timestamp] <message>` | Print `ERROR: <message>` to stderr |

`-t` prefixes the message with a timestamp.
Colors come from fish's `set_color`.

## Tests

The suite runs in a temp sandbox with a local bare remote, so it never touches your real repos or the network.

```sh
fish tests/run.fish
```

It covers argument parsing, `gits`, `dropChanges`, `createBranch`, `deleteOldBranches` (including worktree removal), `main`, the picker's paging, remote selection, retry, and closed stdin, plus `pwGen`, the loggers, and `updateDevroot`.

### Manual checklist

Two behaviors are hard to automate, so check them by hand after changing them:

- `checkout`: page past ten local branches, switch to the remote list, enter garbage and an out-of-range number, then press Ctrl-D.
- `updateDevroot`: run `updateDevroot -f`, run it with no argument from a directory where `$DEVROOT` is set, run it with `-i <repo>`, and confirm a repo without `origin/HEAD` shows `FAILED` in the summary instead of aborting the run.

## Deprecated: BashLib

The bash scripts in [BashLib](https://github.com/GlenEder/BashLib) have been ported here.
BashLib is kept for history and is no longer maintained.
