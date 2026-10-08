# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

MY_TOOLS="
  gitui     - terminal git ui
  topgrade  - detects which tools you use and runs the appropriate commands to update them
              use  'topgrade --disable gcloud' to skip GCP cli
  eza       - modern replacement for ls
  bottom    - customizable cross-platform graphical process/system monitor for the terminal
  broot     - tool through which you can navigate directories
  lsd       - an ls with a lot of pretty colors and awesome icons
  mc        - cross-platform orthodox file manager
  ncdu      - useful and convenient way to view disk usage
  bmon      - text-based network monitoring and debugging tool for Unix-like systems
  slurm     - relatime network interface monitor
  dust      - alternative to the Linux du command
  xplr      - terminal files explorer
  onefetch  - command-line Git information tool that displays project
              information and code statistics for a local Git repository
  bashtop   - terminal-based resource monitoring utility in Linux
  mapscii   - ascii map
  wthr      - local weather using 'curl https://wttr.in/Manchester'
  hwthr     - home weather
  neofetch  - display system information
  htop      - interactively monitor the system's vital resources
  tree      - command-line program used to recursively list or display the content of a directory
              in a tree-like format
  screenfetch  - display system information
  aafigure  - convert ascci art to image
  jp2       - jpg to ascii art
  bpytop    - terminal resource monitor
  jp2a      - jpeg to ascii
  macchina  - system information
  bandwhich - Terminal bandwidth utilization tool
  dua       - View disk space usage and delete unwanted data, fast
  tokei     - displays statistics about your code
  todo-bin  - cli todo
  notes     - A small CLI note taking tool with your favorite editor see notes --help
  vacuum    - OpenAPI linter https://quobix.com/vacuum/
"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lls='ls -la --sort=size'
alias llt='ls -la --sort=time'
alias cls='clear'
alias h='history'
alias hwthr='curl https://wttr.in/Blackburn'
alias wthr='curl https://wttr.in/Manchester'
alias moon='curl https://wttr.in/Moon'
alias starwars=' telnet towel.blinkenlights.nl'
alias tools='echo $MY_TOOLS'
alias topgr='topgrade -y --disable gcloud'
command -v most >/dev/null 2>&1 && export PAGER="most"

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/snap/bin"
export PATH="$PATH:$HOME/go/bin"
#export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share"

export NOTES_CLI_HOME="$HOME/OneDrive/WorkRepos/notes"
export NOTES_CLI_EDITOR=nano # Set your favorite editor

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

[ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

#. $HOME/mouse.zsh
#zle-toggle-mouse

command -v flatpak >/dev/null 2>&1 && alias wezterm='flatpak run org.wezfurlong.wezterm'

# Settings for this machine only (not committed to the repository).
if [ -f "$HOME/.shellrc.local" ]; then
    source "$HOME/.shellrc.local"
fi
