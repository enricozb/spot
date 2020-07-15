spot_repo() {
  parse "$@" << EOF
    --replace -r replace
EOF

  init_spot_files

  cd $SPOT_FILES
  if [[ ! -d .git ]]; then
    info "initializing git repository at $(dirstyle $SPOT_FILES)"
    git init
  fi

  if [[ -n $(git remote -v) ]]; then
    git remote remove origin
  fi

  git remote add origin "$arg"
  git pull origin master
}
