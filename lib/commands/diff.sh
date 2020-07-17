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
    echo "diffing $spot_file"
    colordiff -r "$spot_file" "$tracked_file"
  done
}
