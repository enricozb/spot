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
  elif [[ ! -f $SPOT_SHARED_MAP_FILE ]]; then
    warn "spot files map $(dirstyle $SPOT_SHARED_MAP_FILE) does not exist"
    did_err=true
  fi

  if [[ $did_err = true ]]; then
    error "you must do '$(bold spot repo)' or '$(bold spot track)'" \
          "before '$(bold spot sync)'"
  fi

  cd $SPOT_FILES
  git pull origin master

  update_commit_times
  read_map

  for spot_file in "${!SPOT_MAP[@]}"; do
    local tracked_file=${SPOT_MAP[$spot_file]}

    # spot_file is the one under $SPOT_FILES
    # tracked_file is the one in the user's filesystem
    time_range spot_range "$spot_file"
    time_range tracked_range "$tracked_file"

    read _ max_s <<< "$spot_range"
    read _ max_t <<< "$tracked_range"

    if [[ $interactive = true ]]; then
      prompt input \
      	"sync $(bold FROM) or $(bold TO) $(dirstyle $spot_file)? [f / t]"
      if [[ $input = f ]]; then
        from=true
      else
        to=true
      fi
    fi

    if [[ $to != true && ( $from = true || $max_t -le $max_s ) ]]; then
      sync_pair $spot_file $tracked_file from
    else
      sync_pair $tracked_file $spot_file to
    fi
  done

  git add .
  if [[ ! -z $(git status -s) ]]; then
    git commit -m "manual sync"
    git push --set-upstream origin master
  fi
}

sync_pair() {
  local from=$1
  local to=$2
  local direction=$3

  if [[ $direction = to ]]; then
      info "sync $(dirstyle $to) $(bold '<-') $(dirstyle $from)"
  else
      info "sync $(dirstyle $from) $(bold '->') $(dirstyle $to)"
  fi

  if [[ ! -e $to ]]; then
    mkdir -p $(dirname $to)
  elif [[ -d $from ]] && [[ -d $to ]]; then
    rm -r $to
  elif [[ ! -f $from ]] || [[ ! -f $to ]]; then
    error "invalid sync from $(dirstyle $from) to $(dirstyle $to)" \
          "since they are of different types"
  fi

  cp -r -p $from $to
}

read_map() {
  declare -g -A SPOT_MAP
  # read from shared map
  while IFS="" read -r line; do
    IFS=";" read spot_file tracked_file <<< "$line"

    # remove whitespace
    spot_file="${spot_file//[[:space:]]/}"
    tracked_file="${tracked_file//[[:space:]]/}"

    if [[ -z $spot_file ]] || [[ -z $tracked_file ]]; then
      error "malformed map file $(dirstyle $SPOT_SHARED_MAP_FILE)" \
            "on line '$(bold $line)'"
    fi
    SPOT_MAP["$spot_file"]="$tracked_file"
  done < $SPOT_SHARED_MAP_FILE

  # read from custom map to override shared rules
  if [[ -f $SPOT_CUSTOM_MAP_FILE ]]; then
    while IFS="" read -r line; do
      IFS=";" read spot_file tracked_file <<< "$line"

      # remove whitespace
      spot_file=${spot_file//[[:space:]]/}
      tracked_file=${tracked_file//[[:space:]]/}

      if [[ -z $spot_file ]] || [[ -z $tracked_file ]]; then
        error "malformed map file $(dirstyle $SPOT_CUSTOM_MAP_FILE)" \
              "on line '$(bold $line)'"
      fi
      SPOT_MAP[$spot_file]=$tracked_file
    done < $SPOT_CUSTOM_MAP_FILE
  fi
}
