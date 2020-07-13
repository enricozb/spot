spot_install() {
  local spot_path="$HOME/.local/bin/spot"
  if [[ ! -f $spot_path ]]; then
    mkdir -p "$HOME/.local/bin/"
    ln -s $(realpath "$0") "$spot_path"
    info "installed spot to $(dirstyle $spot_path)"
    info "make sure to add $(dirstyle $HOME/.local/bin/) to your path"
  else
    info "spot is already installed in $(dirstyle $spot_path)"
  fi
}
