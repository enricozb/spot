spot_edit() {
  parse "$@" << EOF
    --shared -s shared
    --custom -c custom
EOF
  if [[ $shared = true ]] && [[ $custom = true ]]; then
    error "for '$(bold spot edit)' only one of $(bold --shared)"\
          "or '$(bold --custom)' can be set"
  fi

  local spot_map_file=$SPOT_SHARED_MAP_FILE
  if [[ $custom = true ]]; then
    spot_map_file=$SPOT_CUSTOM_MAP_FILE
  fi

  if [[ $custom = true ]] || [[ -f $spot_map_file ]]; then
    if [[ -n $EDITOR ]]; then
      $EDITOR $spot_map_file
    elif [[ -n $VISUAL ]]; then
      $VISUAL $spot_map_file
    else
      error "EDITOR and VISUAL are not set, can't edit spot map"
    fi
  else
    warn "track a directory or sync with a repo first"
    error "missing spot mapping $(dirstyle $spot_map_file)"
  fi
}
