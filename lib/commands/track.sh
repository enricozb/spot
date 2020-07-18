spot_track() {
  parse "$@" << EOF
    --dir -d : directory
    --force -f force
EOF
  required track "$arg" "positional"
  arg="$(realpath $arg)"

  if [[ ! -e $arg ]]; then
    error "$(dirstyle $arg) does not exist"
  fi
  arg="${arg%/}" # strip forward slash

  local dest
  if [[ -f $arg ]]; then
    required track "$directory" "(--dir | -d)" \
      "if argument is a file"

    dest="$directory/$(basename $arg)"
  elif [[ -d $arg ]]; then
    dest="$(basename $arg)"
  fi

  init_spot_files

  if [[ -e $dest ]]; then
    error "$(dirstyle $dest) is already being tracked"
  fi
  cd $SPOT_FILES

  sync_pair "$arg" "$dest"

  echo "$dest ; $arg" >> "$SPOT_SHARED_MAP_FILE"
}
