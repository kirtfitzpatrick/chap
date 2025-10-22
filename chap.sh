#!/usr/bin/env bash

VERSION=3.0.0

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
GREY_BG='\033[47;30m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIRM_ALL=0
BRIEF_ENABLED=1

function usage {
  HELP_TEXT=$(
    cat <<HELP_MSG
Usage:
  chap [-hV]
Options:
  -h|--help          Print this help dialogue and exit
  -V|--version       Print the current version and exit

Logging:
  ${CYAN}info_msg${NC}           MESSAGE
  ${GREEN}nominal_msg${NC}        MESSAGE
  ${YELLOW}attention_msg${NC}      MESSAGE
  ${RED}warning_msg${NC}        MESSAGE
  ${PURPLE}mod_msg${NC}            MESSAGE

Evaluation:
  ${CYAN}info_cmd${NC}           COMMAND [ MESSAGE ]
  ${GREEN}nominal_cmd${NC}        COMMAND [ MESSAGE ]
  ${YELLOW}attention_cmd${NC}      COMMAND [ MESSAGE ]
  ${RED}warning_cmd${NC}        COMMAND [ MESSAGE ]
  ${PURPLE}mod_cmd${NC}            COMMAND [ MESSAGE ]

Internal:
  ${BLUE}echo_cmd${NC}           COMMAND
  ${BLUE}echo_eval_cmd${NC}      COMMAND
  display_link       FILE_LINK_OR_DIR_PATH
  brief_echo         OUTPUT_BUFFER
  brief_eval         COMMAND
* enable_brief_eval  # truncate output w/line count (default)
* enable_raw_eval    # full, raw output

Execution control:
  read_to_var          VAR_NAME COMMAND # Requires variable to be declared beforehand
  halt_read_to_var     VAR_NAME COMMAND # Same as above but exits on error
  halt_on_error        COMMAND # Exits on any error in a pipe
  halt_on_error_silent COMMAND # Same as above but no output unless error

String utilities:
  kebab_case           STRING
  pascal_case          STRING
  snake_case           STRING
  lowercase            STRING

Special purpose:
  print_header       "\$0 \$*"
  verify_line_count  LABEL COMPARISON_OP VALUE COMMAND
  confirm_cmd        COMMAND [ MESSAGE ]
* confirm_reset      # Reset auto-confirm
* prompt_var         MESSAGE VAR_TO_SET DEFAULT

* Commands that remember state or set variables for you will require you to 
  source chap from your script so the commands can run as function calls in 
  the same shell.
  E.g.
    source \$(which chap)

HELP_MSG
  )
  printf "${HELP_TEXT}\n\n"
}

# Helper Functions
function chap_info_msg {
  printf "${CYAN}Info:${NC} $1 \n"
}

function chap_nominal_msg {
  printf "${GREEN}Nominal:${NC} $1 \n"
}

function chap_attention_msg {
  printf "${YELLOW}Attention:${NC} $1 \n"
}

function chap_warning_msg {
  printf "${RED}Warning:${NC} $1 \n"
}

# For backwards compatibility
function chap_modification_msg {
  chap_mod_msg "$1"
}

function chap_mod_msg {
  printf "${PURPLE}Modification:${NC} $1 \n"
}

function chap_echo_cmd {
  printf "${BLUE}"
  echo "${1}"
  printf "${NC}"
}

function chap_echo_eval_cmd {
  chap_echo_cmd "${1}"
  chap_brief_eval "${1}"
}

function chap_display_link {
  local LINK=$1
  local TARGET

  if [[ -L "${LINK}" ]]; then
    TARGET=$(readlink "${LINK}")
    printf "%s -> ${CYAN}%s${NC}\n" "${LINK}" "${TARGET}"
  else
    echo "${LINK}"
  fi
}

function chap_brief_echo {
  local OUTPUT=$1
  local LINE_COUNT=$(echo "${OUTPUT}" | wc -l)
  local LINE_NUM=0
  local MAX_LINES=10

  if [[ "${OUTPUT}" != "" ]]; then
    local IFS="" # Needed to keep leading whitespace

    echo "${OUTPUT}" | while read -r LINE; do
      LINE_NUM=$((${LINE_NUM} + 1))
      chap_display_link "${LINE}"

      if [[ ${LINE_NUM} -eq ${MAX_LINES} && ${LINE_COUNT} -gt ${MAX_LINES} ]]; then
        printf " ... [ $((${LINE_COUNT} - ${MAX_LINES})) more lines ]\n"
        break
      fi
    done
  fi
}

function chap_brief_eval {
  local OUTPUT
  local RETURN_VALUE

  if [[ ${BRIEF_ENABLED} -eq 0 ]]; then
    eval "${1}"
    RETURN_VALUE=$?
  else
    OUTPUT=$(eval "${1}")
    RETURN_VALUE=$?
    chap_brief_echo "${OUTPUT}"
  fi

  return ${RETURN_VALUE}
}

function chap_enable_raw_eval() {
  BRIEF_ENABLED=0
}

function chap_enable_brief_eval() {
  BRIEF_ENABLED=1
}

function chap_info_cmd {
  local CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_info_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_info_msg "${BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"

  return $?
}

function chap_nominal_cmd {
  local CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_nominal_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_nominal_msg "${BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"

  return $?
}

function chap_attention_cmd {
  local CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_attention_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_attention_msg "${BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"

  return $?
}

function chap_warning_cmd {
  local CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_warning_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_warning_msg "${BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"

  return $?
}

# For backwards compatibility
function chap_modification_cmd {
  if [[ $# -eq 1 ]]; then
    chap_mod_cmd "$1"
  else
    chap_mod_cmd "$1" "$2"
  fi
}

function chap_mod_cmd {
  local CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_mod_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_mod_msg "${BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"

  return $?
}

# _verify_line_count "name of things" "-gt" 0 "ls /some/thing | grep somepattern"
# arg 1: human readable name for the thing to include in output
# arg 2: comparison operator to use
# arg 3: number to compare line count to
# arg 4: command string to eval and count lines of
function chap_verify_line_count {
  local LABEL=$1
  local COMPARATOR=$2
  local CORRECT=$3
  local CMD=$4
  local ACTUAL=$(eval "${CMD}" | wc -l | awk '{print $1}')
  local RETURN_VALUE

  if eval "[[ ${ACTUAL} ${COMPARATOR} ${CORRECT} ]]"; then
    chap_nominal_msg "${ACTUAL} ${LABEL} found."
    RETURN_VALUE=0
  else
    chap_warning_msg "${ACTUAL} ${LABEL} found. Should be [[ ${COMPARATOR} ${CORRECT} ]]"
    RETURN_VALUE=1
  fi

  chap_echo_cmd "${CMD}"
  chap_brief_eval "${CMD}"

  return $RETURN_VALUE
}

# CMD=$1 First arg is command to confirm before executing
# MSG=$2 If second argument passed, display as info message
function chap_confirm_cmd {
  local CMD=$1
  local CONFIRM
  local RETURN_VALUE

  if [[ $# -eq 2 ]]; then
    chap_info_msg "${2}"
  fi

  chap_echo_cmd "${CMD}"

  if [[ ${CONFIRM_ALL} -eq 0 ]]; then
    printf "${PURPLE}Execute (a=all, s=skip):${NC} "
    read CONFIRM
  else
    printf "${PURPLE}Execute (auto confirmed):${NC}\n"
    CONFIRM=''
  fi

  if [[ "${CONFIRM}" == "a" ]]; then
    CONFIRM_ALL=1
    CONFIRM=''
  fi

  case ${CONFIRM} in
  s)
    RETURN_VALUE=0
    ;;
  "")
    printf "${CYAN}Initiated at:${NC} %s\n" "$(date "+%R:%S")"
    eval "${CMD}"
    RETURN_VALUE=$?
    printf "${CYAN}Completed at:${NC} %s\n" "$(date "+%R:%S")"
    ;;
  *)
    chap attention_msg "Invalid command."
    RETURN_VALUE=1
    ;;
  esac

  return ${RETURN_VALUE}
}

function chap_confirm_reset {
  CONFIRM_ALL=0
}

function chap_prompt_var {
  local MSG="$1"
  local VAR_TO_SET="$2"
  local DEFAULT

  if [[ $# -eq 3 ]]; then
    DEFAULT=$3
    read -e -p "${MSG}: " -i "${DEFAULT}" -r INPUT
  else
    read -e -p "${MSG}: " -r INPUT
  fi

  declare -g ${VAR_TO_SET}="${INPUT}"
  printf "${CYAN}Info:${NC} "
  echo "${VAR_TO_SET}='${INPUT}'"
}

function chap_read_to_var {
  local VAR_NAME=$1
  local CMD=$2

  chap_echo_cmd "${CMD}"
  _READ_TO_VAR_OUT=$(chap_halt_on_error_silent "${CMD}")
  local EXIT_CODE=$?

  # requires the variable to be declared beforehand. I like this one better.
  eval "${VAR_NAME}='${_READ_TO_VAR_OUT}'" 

  return ${EXIT_CODE}
}

function chap_halt_read_to_var {
  chap_read_to_var $1 "$2"
  local EXIT_CODE=$?

  if [ ${EXIT_CODE} -ne 0 ]; then
    exit ${EXIT_CODE}
  fi

  return ${EXIT_CODE}
}

function chap_halt_on_error {
  local CMD="$@"

  chap_echo_cmd "${CMD}"
  chap_halt_on_error_silent "${CMD}"

  return $?
}

function chap_halt_on_error_silent {
  local CMD="$@"

  set -o pipefail
  eval "${CMD}"
  local EXIT_CODE=$?
  set +o pipefail

  if [ ${EXIT_CODE} -ne 0 ]; then
    echo "ERROR: ${CMD} failed with exit code: ${EXIT_CODE}" >/dev/stderr
    exit ${EXIT_CODE}
  fi

  return ${EXIT_CODE}
}

function chap_kebab_case {
  ${SCRIPT_DIR}/lodash.js kebabCase $@
}

function chap_pascal_case {
  ${SCRIPT_DIR}/lodash.js pascalCase $@
}

function chap_snake_case {
  ${SCRIPT_DIR}/lodash.js snakeCase $@
}

function chap_lowercase {
  STR="$@"
  echo "${STR@L}"
}

# chap print_header "$0 $*"
function chap_print_header {
  local COMMAND_LINE=$1
  local HORIZONTAL_RULE=""
  local TERMINAL=$(env | grep 'TERM')
  local TERM_WIDTH

  if [[ "${TERMINAL}" == '' || "${TERMINAL}" == 'TERM=unknown' ]]; then
    TERM_WIDTH='80'
  else
    TERM_WIDTH=$(tput cols)
  fi

  for ((i = 0; i < ${TERM_WIDTH}; i++)); do
    HORIZONTAL_RULE="${HORIZONTAL_RULE}-"
  done

  printf "\n${GREY_BG}${HORIZONTAL_RULE}${NC}\n"
  printf "${CYAN}Host:${NC}        %s\n" "$(hostname)"
  printf "${CYAN}Command:${NC}     %s\n" "${COMMAND_LINE}"
  printf "${CYAN}Working Dir:${NC} %s\n" "$(pwd)"
  echo ""
}

chap() {
  local opt="$1"
  local cmd=""
  shift

  case "${opt}" in
  -h | --help)
    usage
    return 0
    ;;
  -V | --version)
    echo "$VERSION"
    return 0
    ;;
  *)
    cmd="chap_${opt}"
    if type "${cmd}" >/dev/null 2>&1; then
      "${cmd}" "${@}"
      return $?
    else
      if [ ! -z "${opt}" ]; then
        error "Unknown argument: \`${opt}'"
      fi
      usage
      return 1
    fi
    ;;
  esac
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f chap
else
  chap "${@}"
  exit $?
fi
