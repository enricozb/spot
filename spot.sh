#!/bin/bash

set -e

SPOTFILES_DIR="$XDG_CONFIG_HOME/spot"
SPOTFILES_CONFIG="$SPOTFILES_DIR/spot-config"
DRY_RUN=0
VERBOSE=0

# ---------------------------------- style ----------------------------------
bold() {
  echo "$(tput bold)$@$(tput sgr0)"
}

dirstyle() {
  echo "$(tput setaf 2)$@$(tput sgr0)"
}

info() {
  echo "$(tput setaf 3)$@$(tput sgr0)"
}

warn() {
  local NEWLINE=$([ $DRY_RUN -eq 1 -o $VERBOSE -eq 1 ] && echo "\n")
  echo -e "$NEWLINE$(tput setaf 1)INFO:$(tput sgr0) $@"
}

title() {
  echo -e "\n$(tput smul)$@$(tput rmul)"
}

error() {
  echo -e "\n$(bold Error): $@"
  exit 1
}


# ----------------------------------- ops -----------------------------------
cmd() {
  if [[ $DRY_RUN -eq 0 ]]; then
    [ $VERBOSE -eq 1 ] && echo "$(info +) $1"
    eval $1
  else
    echo "$(info -) $1"
  fi
}

commit() {
  if [[ -n $(git status --porcelain) ]]; then
    local REDIRECT=$([ "$VERBOSE" -eq 0 ] && echo "> /dev/null")
    cmd "git add --all $REDIRECT"
    cmd "git commit -m '$1' $REDIRECT"
  fi
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
  local FLAGS=$([ "$VERBOSE" -eq 1 ] && echo "-itau" || echo "-tau")
  cmd "rsync --exclude '.git' $FLAGS $DRY_RUN_FLAG '$1' '$SPOTFILES_DIR/$2' $REDIRECT"
}

print_usage() {
  title "How to use spot:"
  cat << EOF
spot - dotfile manager

Usage: spot [options] command [args...]
  spot add [(-d | --dir) name] (folder | files...)
  spot list
  spot repo url
  spot sync

Commands:
  add   Starts tracking a file or folder. If tracking a single file, you must
        specify which folder it should be tracked under with --dir <name>. For
        example, 'spot add ~/.tmux.conf --dir tmux'.

  list  Show a tree of all tracked files.

  repo  Set the upstream repository for your dotfiles.

  sync  Synchronize tracked files. This uses rsync to sync from local to repo
        first, and then from repo to local. Based on timestamps, rsync decides
        whether or not to overwrite a file.
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
      --dir)     set -- "$@" "-d";;
      --dry-run) set -- "$@" "-D";;
      --help)    set -- "$@" "-h";;
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
    add|list|repo|sync)
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
  cmd "cd '$SPOTFILES_DIR'"
  spot_${cmd} $args
}


# --------------------------------- commands ---------------------------------
spot_add() {
  local arg=${1%/}
  shift

  local tracking_dir
  OPTIND=1
  while getopts "d:" OPTION
  do
    case "$OPTION" in
      "d")
        tracking_dir="${OPTARG%/}";;
    esac
  done

  if [ -d "$arg" ]; then
    warn "tracking dotfiles folder $(dirstyle $arg)"
    track "$arg/" "$(basename $arg)"
    commit "tracking $(basename $arg)"

  elif [[ -f $arg ]]; then
    if [[ -z ${tracking_dir+x} ]]; then
      error "adding a single file requires $(bold '--dir <name>') to be set"
    fi

    local src="$arg"
    local dst="$tracking_dir/$(basename $arg)"

    warn "tracking $(dirstyle $src) under $(dirstyle $tracking_dir/)"
    cmd "mkdir $(dirname $dst)"
    track "$src" "$dst"
    commit "tracking $tracking_dir/$(basename $arg)"
  else
    echo "'$arg' is not a file or directory"
    exit 1
  fi
}

spot_list() {
  cmd "tree '$SPOTFILES_DIR' -a -I '.git*|spot-config' -C"
}

spot_repo() {
  cmd "git remote add origin $1"
}

spot_sync() {
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

    sync "$orig" "$spot"
  done < <(cat $SPOTFILES_CONFIG | sort)

  commit "manual sync"
  push
}

main "$@"
