RESET="\033[0m"
GREEN="\033[0;32m"
BOLD="\033[1m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREY="\033[0;37m"

x:isverbose() {
  [[ $__VERBOSE__ == "true" ]] && return 0 || return 1
}

x:log() {
  if x:isverbose; then
    echo -e "${*}"
  fi
}

x:err() {
  echo -e "${RED}${BOLD}Error${RESET}${RED} - ${*}${RESET}"
  exit 1
}

x:success() {
  echo -e "${GREEN}${BOLD}Success${RESET}${GREEN} - ${*}${RESET}"
  echo -e ""
}

# check_errors: Check if the previous command fails
# params
#   - retcode int
x:check() {
  local _code=$1
  shift
  local _message="${*}"
  [[ "$_code" != "0" ]] && x:err "$_message"
}
