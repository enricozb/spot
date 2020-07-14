update_commit_times() {
  cd $SPOT_FILES
  IFS="
  "
  for file in $(git ls-files); do
    local time=$(git log --pretty=format:%cd -n 1 --date=iso -- "$file")
    time=$(date -d "$time" +%Y%m%d%H%M.%S)
    touch -m -t "$time" "$file"
  done
}

time_range() {
  if [[ ! -e $1 ]]; then
    error "time range for nonexistent file $(dirstyle $1)"
  fi

  find $1 -type f | xargs stat -c %Y | awk '
    NR == 1 { max=$1; min=$1; }
    {
      if ($1 > max) max=$1;
      if ($1 < min) min=$1;
    }
    END {
      printf "%d %d", min, max
    }
  '
}
