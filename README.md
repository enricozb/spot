# Spot - Unbelievably Dumb Dotfile Management

## Install
Push `spot.sh` somewhere special.

## Usage
```
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
```

## Why
I decided to waste time in a different way today.
