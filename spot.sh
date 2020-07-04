#!/bin/bash

set -e

if [[ -z $XDG_CONFIG_HOME ]]; then
  CONFIG_DIR="$HOME/.config"
else
  CONFIG_DIR="$XDG_CONFIG_HOME"
fi


SPOTFILES_DIR="$CONFIG_DIR/spot"
SPOTFILES_CONFIG="$SPOTFILES_DIR/spot-config"
DRY_RUN=0
VERBOSE=0

# ---------------------------------- style ----------------------------------
bold() { echo "$(tput bold)$@$(tput sgr0)"; }
red() { echo "$(tput setaf 1)$@$(tput sgr0)"; }
green() { echo "$(tput setaf 2)$@$(tput sgr0)"; }
yellow() { echo "$(tput setaf 3)$@$(tput sgr0)"; }
blue() { echo "$(tput setaf 4)$@$(tput sgr0)"; }

dirstyle() { echo "$(bold $(blue $@))"; }

info() {
  local NEWLINE=$([ $DRY_RUN -eq 1 -o $VERBOSE -eq 1 ] && echo "\n")
  echo -e "$NEWLINE$(green INFO:) $@"
}

debug() {
  if [[ $DRY_RUN -eq 1 ]] || [[ $VERBOSE -eq 1 ]]; then
    echo -e "\n$(yellow DEBUG:) $@"
  fi
}

warn() {
  local NEWLINE=$([ $DRY_RUN -eq 1 -o $VERBOSE -eq 1 ] && echo "\n")
  echo -e "$NEWLINE$(tput setaf 1)WARN:$(tput sgr0) $@"
}

title() {
  echo -e "\n$(tput smul)$@$(tput rmul)"
}

error() {
  echo -e "\n$(bold $(red ERROR:)) $@"
  exit 1
}


# ----------------------------------- ops -----------------------------------
join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

cmd() {
  if [[ $DRY_RUN -eq 0 ]]; then
    if [[ $VERBOSE -eq 1 ]]; then
      echo "$(yellow +) $1"
    fi
    eval $1
  else
    echo "$(yellow -) $1"
  fi
}

commit() {
  if [[ -n $(git status --porcelain) ]]; then
    local REDIRECT=$([ "$VERBOSE" -eq 0 ] && echo "> /dev/null")
    cmd "git add --all $REDIRECT"
    cmd "git commit -m '$1' $REDIRECT"
    return 0
  else
    info "no changes detected, not committing anything"
    return 1
  fi
}

pull() {
  cmd "git pull origin master"
}

push() {
  cmd "git push -u origin master"
}

track() {
  cmd "echo '$1 -> $2' >> '$SPOTFILES_CONFIG'"
  sync "$@"
}

sync() {
  local DRY_RUN_FLAG=$([ "$DRY_RUN" -eq 1 ] && echo "--dry-run")
  local REDIRECT=$([ "$VERBOSE" -eq 0 ] && echo "> /dev/null")
  local FLAGS=$([ "$VERBOSE" -eq 1 ] && echo "-ita" || echo "-ta")
  local EXTRA="${@:3}"

  cmd "rsync --exclude '.git' $FLAGS $DRY_RUN_FLAG '$1' '$2' $EXTRA $REDIRECT"
}

print_usage() {
  title "How to use spot:"
  cat << EOF
spot - dotfile manager

Usage: spot [options] command [args...]
  spot add [(-d | --dir) name] (folder | files...)
  spot clone url
  spot list
  spot (pull | push)
  spot repo url
  spot sync [(-x | --delete)] [(-f | --from) | (-t | --to)] [(-m | --message)]

Commands:
  add   Starts tracking a file or folder. If tracking a single file, you must
        specify which folder it should be tracked under with --dir <name>. For
        example, 'spot add ~/.tmux.conf --dir tmux'.

  clone Clone a dotfiles repository created with spot.

  list  Show a tree of all tracked files.

  pull  Pulls changes to remote spot repo.

  push  Pushes changes to spot repo.

  repo  Set the upstream repository for your dotfiles.

  sync  Synchronize tracked files. This uses rsync to sync from local to repo
        first, and then from repo to local.Use --delete or -x to remove files
        that were deleted from being tracked. Use --from to sync from the
        repo, otherwise --to syncs to the repo. The --to flag does nothing,
        as it is set by default.
Options:
  --help     prints this message
  --dry-run  prints out the commands and without executing them
  --verbose  prints all commands that are executed

EOF
  exit 1
}

main() {
  # ------------------------------- parse flags -------------------------------
  local arg
  for arg in "$@"; do
    shift
    case "$arg" in
      --delete)  set -- "$@" "-x";;
      --dir)     set -- "$@" "-d";;
      --dry-run) set -- "$@" "-D";;
      --from)    set -- "$@" "-f";;
      --help)    set -- "$@" "-h";;
      --message) set -- "$@" "-m";;
      --to)      set -- "$@" "-t";;
      --verbose) set -- "$@" "-v";;
      --*)       error "unknown option $(bold $arg)";;
      *)         set -- "$@" "$arg";;
    esac
  done

  while getopts "Dhv" OPTION; do
    case "$OPTION" in
      "D")
        info "using --dry-run, not making changes"
        DRY_RUN=1
      ;;
      "h") print_usage;;
      "v") VERBOSE=1;;
    esac
  done

  shift $((OPTIND - 1))


  # ----------------------------- parse command -----------------------------
  if [ -z ${1+x} ]; then
    print_usage
  fi

  local cmd
  local args
  case $1 in
    add|clone|list|pull|push|repo|sync)
      cmd=${1}
      args="${@:2}"
      ;;
    *)
      error "command $(bold $1) not found."
  esac


  # ---------------------------------- init ----------------------------------
  if [ ! -d "$SPOTFILES_DIR" ]; then
    warn "no default dotfile directory, creating $(dirstyle $SPOTFILES_DIR)"
    cmd "mkdir -p '$SPOTFILES_DIR'"
    cmd "cd '$SPOTFILES_DIR'"
    cmd "git init > /dev/null"
  fi

  if [ ! -f "$SPOTFILES_CONFIG" ]; then
    warn "no default spot config, creating $(dirstyle $SPOTFILES_CONFIG)"
    cmd "touch '$SPOTFILES_CONFIG'"
    commit "initial commit of spot config file"
  fi

  # ---------------------------------- main ----------------------------------
  # all operations should be done from within the spotfiles directory
  cd "$SPOTFILES_DIR"
  debug "calling '${cmd}' with args=$args"
  spot_${cmd} "$args"
}


# --------------------------------- commands ---------------------------------
spot_add() {
  local arg=${1%/}
  shift

  local tracking_dir
  OPTIND=1
  while getopts "d:" OPTION; do
    case "$OPTION" in
      "d")
        tracking_dir="${OPTARG%/}";;
    esac
  done

  if [ -d "$arg" ]; then
    local src="$arg/"
    local dst="$(basename $arg)"

    if [[ -d $dst ]]; then
      error "$(dirstyle $src) is already being tracked under $(dirstyle $dst)"
    fi

    info "tracking dotfiles folder $(dirstyle $src)"
    track "$src" "$dst"
    commit "tracking $dst"

  elif [[ -f $arg ]]; then
    if [[ -z ${tracking_dir+x} ]]; then
      error "adding a single file requires $(bold '--dir <name>') to be set"
    fi

    local src="$arg"
    local dst="$tracking_dir/$(basename $arg)"

    if [[ -f $dst ]]; then
      error "$(dirstyle $src) is already being tracked under $(dirstyle $dst)"
    fi

    info "tracking $(dirstyle $src) under $(dirstyle $tracking_dir/)"
    cmd "mkdir $(dirname $dst)"
    track "$src" "$dst"
    commit "tracking $tracking_dir/$(basename $arg)"
  else
    echo "'$arg' is not a file or directory"
    exit 1
  fi

  debug "updating README.md"
  cmd 'echo "# my dotfiles" > README.md'
  cmd 'echo "|Source|Destination|" >> README.md'
  cmd 'echo "|---|---|" >> README.md'
  while read line; do
    read orig spot <<<$(IFS="->"; echo $line)
    if [ ${orig: -1} == "/" ]; then
      cmd "echo '|$spot/|$orig|' >> README.md"
    else
      cmd "echo '|$spot|$orig|' >> README.md"
    fi
  done < <(cat $SPOTFILES_CONFIG | sort)
}

spot_clone() {
  cmd "git clone $1 '$SPOTFILES_DIR'"
}

spot_list() {
  cmd "tree '$SPOTFILES_DIR' -a -I '.git*|spot-config|README.md' -C"
}

spot_pull() { pull; }

spot_push() { push; }

spot_repo() {
  cmd "git remote add origin $1"
}

spot_sync() {
  local extra=()
  local direction="to"
  local message="manual sync"
  OPTIND=1
  while getopts "fm:tx" OPTION; do
    case "$OPTION" in
      "f") direction="from";;
      "t") direction="to";;
      "m") message="$OPTARG";;
      "x") extra+=("--delete");;
    esac
  done
  extra=$(join_by ' ' ${extra[@]})

  debug "sync args='$extra' direction='$direction'"

  while read line; do
    read orig spot <<<$(IFS="->"; echo $line)
    if [[ $direction == "to" ]]; then
      sync "$orig" "$SPOTFILES_DIR/$spot" "$extra"
    elif [[ $direction == "from" ]]; then
      sync "$spot" "$orig" "$extra"
    fi
  done < <(cat $SPOTFILES_CONFIG | sort)

  if commit "$message"; then
    push
  fi
}

main "$@"
