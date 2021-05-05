#!/usr/bin/env bash

VERSION=0.0.4

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
DK_BLUE='\033[0;34m'
LT_BLUE='\033[0;36m' # Cyan
GREY_BG='\033[47;30m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

usage () {
    cat <<HELP_MSG
Usage:
  chap [-hV]
Options:
  -h|--help      Print this help dialogue and exit
  -V|--version   Print the current version and exit
Commands:
  info_msg
  nominal_msg
  attention_msg
  warning_msg
  modification_msg

  info_cmd
  nominal_cmd
  attention_cmd
  warning_cmd
  modification_cmd

  echo_cmd
  display_link
  brief_echo
  brief_eval
  verify_line_count

  begin_line_looping
  end_line_looping

  confirm_cmd
}

HELP_MSG
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

      if [[ ${LINE_COUNT} -eq ${MAX_LINES} ]]; then
        printf " ... [ $((${ACTUAL_LINE_COUNT} - ${MAX_LINES})) more lines ]\n"
        break
      fi
    done
  fi
}

function chap_brief_eval {
  CMD=$1
  MAX_LINES=10
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

# PREV_IFS=$(_begin_line_looping)
function chap_begin_line_looping {
  SAVEIFS=${IFS}
  IFS=$(echo -en "\n\b")
  echo "${SAVEIFS}"
}

# _end_line_looping "${PREV_IFS}"
function chap_end_line_looping {
  IFS=${1}
}

# _verify_line_count "-gt" 0 "ls /some/thing | grep somepattern" "label for output messages"
# arg 1: comparison operator to use
# arg 2: number to compare line count to
# arg 3: command string to eval and count lines of
# arg 4: human readable name for the thing to include in output
function chap_verify_line_count {
  COMPARATOR=$1
  CORRECT=$2
  CMD=$3
  LABEL=$4
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
# 
# Global variables that affect operation:
# CONFIRM_ALL=0 to force confirmation for next command
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
