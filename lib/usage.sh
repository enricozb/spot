usage() {
  cat << EOF
spot - dotfile manager

Usage: spot [options] command [args...]
  spot track [(-d | --dir) name] (directory | files...)
  spot repo url
  spot sync [(-x | --delete)] [(-f | --from) | (-t | --to)] [(-m | --message)]
  spot edit
  spot list

Commands:
  track  Starts tracking a file or directory. If tracking a single file, you
         must specify which directory it should be tracked under with
         --dir <name>. For example, 'spot add ~/.tmux.conf --dir tmux'.

  repo   Set the upstream repository for your dotfiles.

  sync   Synchronize tracked files. This uses rsync to sync from local to repo
         first, and then from repo to local.Use --delete or -x to remove files
         that were deleted from being tracked. Use --from to sync from the
         repo, otherwise --to syncs to the repo. The --to flag does nothing,
         as it is set by default.

  edit   Edit the spot mapping to change where each tracked file syncs to.

  list   Show a tree of all tracked files.

Options:
  --help     print this message
  --dry-run  print commands without executing them
  --verbose  print commands that are executed
EOF
}
