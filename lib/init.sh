init_spot_files() {
  if [[ ! -d $SPOT_FILES ]]; then
    info "creating spot files directory $(dirstyle $SPOT_FILES)"
    mkdir -p $SPOT_FILES
    git init $SPOT_FILES
    pushd $SPOT_FILES > /dev/null
    git config pull.rebase false
    popd > /dev/null
  fi
}
