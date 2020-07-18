usage() {
  cat << EOF
spot - dotfile manager

Usage: spot [options] command [args...]
  spot track [(-d | --dir) name] (directory | file)
  spot repo url
  spot sync [(-f | --from) | (-t | --to) | (-i | --interactive)]
  spot edit [(-c | --custom) | (-s | --shared)]
  spot list
  spot diff

Commands:
  track  Starts tracking a file or directory. If tracking a single file, you
         must specify which directory it should be tracked under with
         --dir <name>. For example, 'spot add ~/.tmux.conf --dir tmux'.

  repo   Set the upstream repository for your dotfiles.

  sync   Synchronize tracked files. Spot uses the timestamps of the files
         being tracked to decide whether to copy to or from those files. To
         force tracking to or from, use --to or --from, respectively. As a
         third option, --interactive lets you individually select whether to
         track to or from each folder.

  edit   Edit the spot mapping to change where each tracked file syncs to.
         The syntax of this file is

           SPOT_FILE ; TRACKED_FILE

         where SPOT_FILE is the copy of the file that spot has saved, and
         TRACKED_FILE is the file currently in use.

         Spot lets you specify custom untracked overrides for each folder.
         This is meant to service the use case where different machines have
         slightly different destinations of where the dotfiles should end up.
         This mapping uses the same syntax, and can be edited with the
         --custom switch. The --shared switch on by default.

  list   Show a tree of all tracked files.

  diff   Show a diff between the files in use and the files that spot has
         saved. Similar to 'spot sync' this uses timestamps to determine which
         file is passed as the first argument to diff. Requires colordiff.

Options:
  --help     print this message
  --verbose  print commands that are executed
EOF
}
