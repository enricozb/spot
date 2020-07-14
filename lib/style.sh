bold() {
  echo "$(tput bold)$@$(tput sgr0)"
}

red() {
  echo "$(tput setaf 1)$@$(tput sgr0)"
}

green() {
  echo "$(tput setaf 2)$@$(tput sgr0)"
}

yellow() {
  echo "$(tput setaf 3)$@$(tput sgr0)"
}

blue() {
  echo "$(tput setaf 4)$@$(tput sgr0)"
}

required() {
  if [[ -z $2 ]]; then
    error "$(bold $1) command requires $3 argument $4"
  fi
}

dirstyle() {
  echo "$(bold $(blue $@))";
}

debug() {
  if [[ $DRY_RUN = true ]] || [[ $VERBOSE = true ]]; then
    echo -e "\n$(yellow DEBUG:) $@"
  fi
}

info() {
  if [[ $DRY_RUN = true ]] || [[ $VERBOSE = true ]]; then
    echo -e "\n$(green INFO:) $@"
  else
    echo -e "$(green INFO:) $@"
  fi
}

prompt() {
  echo -n "$(green PROMPT:) ${@:2}"
  read $1
}

warn() {
  if [[ $DRY_RUN = true ]] || [[ $VERBOSE = true ]]; then
    echo -e "\n$(tput setaf 1)WARN:$(tput sgr0) $@"
  else
    echo -e "$(tput setaf 1)WARN:$(tput sgr0) $@"
  fi
}

error() {
  echo -e "$(bold $(red ERROR:)) $@"
  exit 1
}
