#!/bin/bash

set -e

SPOT_LIB=$(dirname $(realpath "$0"))/lib
SPOT_COMMANDS=$SPOT_LIB/commands
SPOT_DIR=$HOME/.spot
SPOT_FILES=$SPOT_DIR/files
SPOT_SHARED_MAP_FILE=$SPOT_FILES/rules
SPOT_CUSTOM_MAP_FILE=$SPOT_DIR/rules


load_lib() {
  for f in $SPOT_LIB/*.sh; do
    . $f
  done
}


load_commands() {
  for f in $SPOT_LIB/commands/*.sh; do
    . $f
  done
}


run_command() {
  if [[ ! -f $SPOT_COMMANDS/$1.sh ]]; then
    error "Unknown command '$1'"
  else
    load_commands
    spot_$1 "${@:2}"
  fi
}


main() {
  load_lib

  # sets COMMAND and COMMAND_ARGS
  argparse "$@"

  if [[ $HELP = true ]] || [[ -z $COMMAND ]]; then
    usage
    exit 0
  fi

  run_command $COMMAND "${COMMAND_ARGS[@]}"
}


main "$@"
