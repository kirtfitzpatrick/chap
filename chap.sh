#!/usr/bin/env bash

VERSION=1.1.0

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
DK_BLUE='\033[0;34m'
LT_BLUE='\033[0;36m' # Cyan
GREY_BG='\033[47;30m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

CONFIRM_ALL=0


usage () {
  HELP_TEXT=$(cat <<HELP_MSG
Usage:
  chap [-hV]
Options:
  -h|--help      Print this help dialogue and exit
  -V|--version   Print the current version and exit

Logging:
  ${LT_BLUE}info_msg${NC}           MESSAGE
  ${GREEN}nominal_msg${NC}        MESSAGE
  ${YELLOW}attention_msg${NC}      MESSAGE
  ${RED}warning_msg${NC}        MESSAGE
  ${PURPLE}modification_msg${NC}   MESSAGE

Evaluate command:
  ${LT_BLUE}info_cmd${NC}           COMMAND [ MESSAGE ]
  ${GREEN}nominal_cmd${NC}        COMMAND [ MESSAGE ]
  ${YELLOW}attention_cmd${NC}      COMMAND [ MESSAGE ]
  ${RED}warning_cmd${NC}        COMMAND [ MESSAGE ]
  ${PURPLE}modification_cmd${NC}   COMMAND [ MESSAGE ]

Internal:
  ${DK_BLUE}echo_cmd${NC}           COMMAND
  display_link       FILE_LINK_OR_DIR_PATH
  brief_echo         OUTPUT_BUFFER
  brief_eval         COMMAND

Iterate by line:
  begin_line_looping # PREV_IFS=\$(chap begin_line_looping)
  end_line_looping   # chap end_line_looping "\${PREV_IFS}"

Special purpose:
  print_header       "\$0 \$*"
  verify_line_count  LABEL COMPARISON_OP VALUE COMMAND
  confirm_cmd        COMMAND [ MESSAGE ]
  confirm_reset      # Reset auto-confirm
HELP_MSG
)
  printf "${HELP_TEXT}\n\n"
}

# Helper Functions
function chap_info_msg {
  printf "${LT_BLUE}Info:${NC} $1 \n"
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

function chap_modification_msg {
  printf "${PURPLE}Modification:${NC} $1 \n"
}

function chap_echo_cmd {
  printf "${DK_BLUE}"
  echo "${1}"
  printf "${NC}"
}

function chap_display_link {
  LINK=$1

  if [[ -h "${LINK}" ]]; then
    TARGET=`readlink ${LINK}`
    printf "${LINK} -> ${LT_BLUE}${TARGET}${NC}\n"
  else
    echo "${LINK}"
  fi
}

function chap_brief_echo {
  OUTPUT=$1
  ACTUAL_LINE_COUNT=$(echo "${OUTPUT}" | wc -l)
  LINE_COUNT=0

  if [[ "${OUTPUT}" != "" ]]; then
    echo "${OUTPUT}" | while read LINE ; do
      LINE_COUNT=$((${LINE_COUNT} + 1))
      chap_display_link "${LINE}"

      if [[ ${LINE_COUNT} -eq ${MAX_LINES} && ${ACTUAL_LINE_COUNT} -gt ${MAX_LINES} ]]; then
        printf " ... [ $((${ACTUAL_LINE_COUNT} - ${MAX_LINES})) more lines ]\n"
        break
      fi
    done
  fi
}

function chap_brief_eval {
  CMD=$1
  OUTPUT=$(eval "${CMD}")

  chap_brief_echo "${OUTPUT}"
}

function chap_info_cmd {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_info_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_info_msg "${DK_BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"
}

function chap_nominal_cmd {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_nominal_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_nominal_msg "${DK_BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"
}

function chap_attention_cmd {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_attention_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_attention_msg "${DK_BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"
}

function chap_warning_cmd  {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_warning_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_warning_msg "${DK_BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"
}

function chap_modification_cmd  {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_modification_msg "${2}"
    chap_echo_cmd "${CMD}"
  else
    chap_modification_msg "${DK_BLUE}${CMD}${NC}"
  fi

  chap_brief_eval "${CMD}"
}

# PREV_IFS=$(chap begin_line_looping)
function chap_begin_line_looping {
  SAVEIFS=${IFS}
  IFS=$(echo -en "\n\b")
  echo "${SAVEIFS}"
}

# chap end_line_looping "${PREV_IFS}"
function chap_end_line_looping {
  IFS=${1}
}

# _verify_line_count "name of things" "-gt" 0 "ls /some/thing | grep somepattern"
# arg 1: human readable name for the thing to include in output
# arg 2: comparison operator to use
# arg 3: number to compare line count to
# arg 4: command string to eval and count lines of
function chap_verify_line_count {
  LABEL=$1
  COMPARATOR=$2
  CORRECT=$3
  CMD=$4
  ACTUAL=`eval ${CMD} | wc -l | awk '{print $1}'`

  if eval "[[ ${ACTUAL} ${COMPARATOR} ${CORRECT} ]]"; then
    chap_nominal_msg "${ACTUAL} ${LABEL} found."
  else
    chap_warning_msg "${ACTUAL} ${LABEL} found. Should be [[ ${COMPARATOR} ${CORRECT} ]]"
  fi

  chap_echo_cmd "${CMD}"
  chap_brief_eval "${CMD}"
}

# CMD=$1 First arg is command to confirm before executing
# MSG=$2 If second argument passed, display as info message
function chap_confirm_cmd {
  CMD=$1

  if [[ $# -eq 2 ]]; then
    chap_info_msg "${2}"
  fi

  chap_echo_cmd "${CMD}"

  if [[ ${CONFIRM_ALL} -eq 0 ]] ; then
    printf "${PURPLE}Execute (a=all, s=skip):${NC} ";
    read CONFIRM
  else
    printf "${PURPLE}Execute (auto confirmed):${NC}\n";
  fi

  case ${CONFIRM} in
    [sS]* ) SKIP=1 ;;
    [aA]* ) CONFIRM_ALL=1 ;&
    * )
      printf "${LT_BLUE}Initiated at:${NC} %s\n" `date "+%R:%S"`;
      eval "${CMD}"
      printf "${LT_BLUE}Completed at:${NC} %s\n" `date "+%R:%S"`;
      ;;
  esac
}

function chap_confirm_reset {
  CONFIRM_ALL=0
}

# chap print_header "$0 $*"
function chap_print_header {
  COMMAND_LINE=$1

  printf "\n${GREY_BG}---------------------------------------------------------------------------------------------------------------------------------------------------------------${NC}\n"
  printf "${LT_BLUE}Host:${NC}        `hostname`\n"
  printf "${LT_BLUE}Command:${NC}     ${COMMAND_LINE}\n"
  printf "${LT_BLUE}Working Dir:${NC} `pwd`\n"
  echo ""
}

chap () {
  local opt="$1"
  local cmd=""
  shift

  case "${opt}" in
    -h|--help)
      usage
      return 0
      ;;
    -V|--version)
      echo "$VERSION"
      return 0
      ;;
    *)
      cmd="chap_${opt}"
      if type "${cmd}" > /dev/null 2>&1; then
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
