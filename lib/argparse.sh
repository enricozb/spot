argparse() {
  while true; do
    case "$1" in
      -v | --verbose ) VERBOSE=true; shift ;;
      -h | --help )    HELP=true; shift ;;
      -n | --dry-run ) DRY_RUN=true; shift ;;
      -* )             error "Unrecognized option '$1'" ;;
      * ) break;;
    esac
  done

  COMMAND=$1
  COMMAND_ARGS=("${@:2}")
}

parse() {
  arg_opts=()
  while read line; do
    arg_opts+=("$line")
  done

  while true; do
    if [[ ${#@} = 0 ]]; then
      break
    fi

    for arg_opt in "${arg_opts[@]}"; do
      read long short flag pos <<< "$arg_opt"
      case "$1" in
        $short | $long )
            # positional arguments
            if [[ $flag = : ]]; then
              eval "$pos"='$2'
              shift
            else
              eval "$flag"=true
            fi
            break
            ;;
        -* ) continue ;;
        * )
            if [[ -z $arg ]]; then
              arg=$1
              break
            else
              error "Unexpected argument or option '$1'"
            fi
            ;;
      esac
      error "Unexpected argument or option '$1'"
    done

    shift
  done
}
