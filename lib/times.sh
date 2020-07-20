update_commit_times() {
  if [[ ! -d $SPOT_FILES ]]; then
    error "update_commit_times requires $(dirstyle $SPOT_FILES) to exist"
  fi

  cd $SPOT_FILES
  while IFS= read -r file; do
    debug "updating times for '$file'"
    local time=$(git log --pretty=format:%cd -n 1 --date=iso -- "$file")
    time=$(date -d "$time" +%Y%m%d%H%M.%S)
    touch -m -t "$time" "$file"
  done < <(git ls-files)
}

time_range() {
  local retvar=$1
  local file=$2

  debug "computing time range for '$file' into '$1'"

  if [[ ! -e $file ]]; then
    eval "$retvar='0 0'"
    return 0
  fi

  local max=0
  local min=0
  while IFS= read -r file; do
    local time=$(stat -c %Y "$file")
    if [[ $max = 0 || $max < $time ]]; then
      max=$time
    fi

    if [[ $min = 0 || $min > $time ]]; then
      min=$time
    fi
  done < <(find "$file" -type f)

  debug "time computed as '$min $max'"
  eval "$retvar='$min $max'"
}
