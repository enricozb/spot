spot_edit() {
  if [[ -f $SPOT_MAPPING ]]; then
    $EDITOR $SPOT_MAPPING
  else
    info "missing spot mapping $(dirstyle $SPOT_MAPPING)"
    info "track a file or directory first"
  fi
}
