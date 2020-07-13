spot_track() {
  parse "$@" << EOF
    --dir -d : directory
    --force -f force
EOF

  required track "$arg" "positional"

  arg="${arg%/}"

  if [[ -f $arg ]]; then
    required track "$directory" "(--dir | -d)" \
      "if argument is a file"
  elif [[ -d $arg ]]; then
    directory="$(basename $arg)"
  else
    error "$(dirstyle $arg) does not exist"
  fi

  local dest_dir=$SPOT_FILES/$directory

  if [[ -d $dest_dir ]]; then
    error "$(dirstyle $dest_dir) is already being tracked"
  fi

  if [[ ! -d $SPOT_FILES ]]; then
    info "creating spot files directory $(dirstyle $SPOT_FILES)"
    mkdir -p $SPOT_FILES
  fi

  info "tracking $(dirstyle $arg) under $(dirstyle $directory)"
  if [[ -f $arg ]]; then
    mkdir $dest_dir
    cp -p $arg $dest_dir
  else
    cp -r -p $arg $dest_dir
  fi
}
