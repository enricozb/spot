spot_diff() {
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
          "before '$(bold spot diff)'"
  fi

  cd $SPOT_FILES
  git pull origin master > /dev/null 2>&1

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

    # colordiff returns an error code of 1 if diffs exist, and 0 otherwise
    # because of set -e, any non-zero exit code causes the script to stop
    # the || : guarantees a 0 exit code
    if (( $max_s <= $max_t )); then
      colordiff -r $spot_file $tracked_file || :
    else
      colordiff -r $tracked_file $spot_file || :
    fi
  done
}
