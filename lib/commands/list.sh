spot_list() {
  tree "$SPOT_FILES" -a -I '.git*|spot-config|README.md' -C
}
