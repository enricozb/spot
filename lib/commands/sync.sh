spot_sync() {
  parse "$@" << EOF
    --interactive -i interactive
    --from -f from
    --to -t to
EOF

  local allopts="$interactive$from$to"
  if [[ ${#allopts} > 4 ]]; then
    error "only one of $(bold --interactive), $(bold --from), $(bold --to)" \
          "can be set for '$(bold spot sync)'"
  fi

  local did_err
  if [[ ! -d $SPOT_FILES ]]; then
    warn "spot files directory $(dirstyle $SPOT_FILES) does not exist"
    did_err=true
  elif [[ ! -f $SPOT_MAP_FILE ]]; then
    warn "spot files map $(dirstyle $SPOT_MAP_FILE) does not exist"
    did_err=true
  fi

  if [[ $did_err = true ]]; then
    error "you must do '$(bold spot repo)' or '$(bold spot track)'" \
          "before '$(bold spot sync)'"
  fi

  cd $SPOT_FILES
  git pull remote origin
  update_commit_times

  read_map SPOT_MAP $SPOT_MAP_FILE

  for spot_file in "${!SPOT_MAP[@]}"; do
    local tracked_file=${SPOT_MAP[$spot_file]}
    # spot_file is the one under $SPOT_FILES
    # tracked_file is the one in the user's filesystem
    echo $spot_file -> $tracked_file
    read _ max_s <<< $(time_range $spot_file)
    read _ max_t <<< $(time_range $tracked_file)

    local interactive_from=false
    if [[ $interactive = true ]]; then
      prompt input \
      	"sync $(bold FROM) or $(bold TO) $(dirstyle $spot_file)? [f / t]"
      if [[ $input = f ]]; then
        interactive_from=true
      fi
    fi

    if [[ $interactive_from = true ]] || (( $max_t < $max_s )) && [[ $to != true ]]; then
      info "sync'd $(bold FROM) $spot_file"
      sync_pair $spot_file $tracked_file
    else
      info "sync'd $(bold ' TO ') $spot_file"
      sync_pair $tracked_file $spot_file
    fi
  done
}

sync_pair() {
  local from=$1
  local to=$1

  if [[ -f $from ]] && [[ -f $to ]]; then
    cp -p $from $to
  elif [[ -d $from ]] && [[ -d $to ]]; then
    rm -r $to
    cp -r -p $from $to
  else
    error "invalid sync from $(dirstyle $from) to $(dirstyle $to)" \
          "since they are of different types"
  fi
}

declare -A SPOT_MAP
read_map() {
  # read from shared map
  while IFS="" read -r line; do
    IFS=";" read spot_file tracked_file <<< "$line"
    if [[ -z $spot_file ]] || [[ -z $tracked_file ]]; then
      error "malformed map file $(dirstyle $SPOT_SHARED_MAP_FILE)" \
            "on line '$(bold $line)'"
    fi
    SPOT_MAP[$spot_file]=$tracked_file
  done < $SPOT_SHARED_MAP_FILE

  # read from custom map to override shared rules
  while IFS="" read -r line; do
    IFS=";" read spot_file tracked_file <<< "$line"
    if [[ -z $spot_file ]] || [[ -z $tracked_file ]]; then
      error "malformed map file $(dirstyle $SPOT_CUSTOM_MAP_FILE)" \
            "on line '$(bold $line)'"
    fi
    SPOT_MAP[$spot_file]=$tracked_file
  done < $SPOT_CUSTOM_MAP_FILE
}
