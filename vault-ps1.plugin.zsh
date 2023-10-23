#!/usr/bin/env bash

# Vault prompt helper for bash/zsh
# Displays current VAULT_ADDR

# Copyright 2023 Konstantinos Katsantonis
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Debug
[[ -n $DEBUG ]] && set -x

# Default values for the prompt
# Override these values in ~/.zshrc or ~/.bashrc
VAULT_PS1_SYMBOL_ENABLE="${VAULT_PS1_SYMBOL_ENABLE:-true}"
VAULT_PS1_SYMBOL_DEFAULT=${VAULT_PS1_SYMBOL_DEFAULT:-$'\u25bc'}
VAULT_PS1_SYMBOL_PADDING="${VAULT_PS1_SYMBOL_PADDING:-false}"
VAULT_PS1_SYMBOL_USE_IMG="${VAULT_PS1_SYMBOL_USE_IMG:-false}"
VAULT_PS1_TRIM_SCHEME="${VAULT_PS1_TRIM_SCHEME:-true}"

VAULT_PS1_PREFIX="${VAULT_PS1_PREFIX-(}"
VAULT_PS1_SEPARATOR="${VAULT_PS1_SEPARATOR-|}"
VAULT_PS1_SUFFIX="${VAULT_PS1_SUFFIX-)}"

VAULT_PS1_SYMBOL_COLOR="${VAULT_PS1_SYMBOL_COLOR-blue}"
VAULT_PS1_ADDR_COLOR="${VAULT_PS1_NS_COLOR-green}"
VAULT_PS1_BG_COLOR="${VAULT_PS1_BG_COLOR}"

VAULT_PS1_DISABLE_PATH="${HOME}/.vault/vault-ps1/disabled"

# Determine our shell
if [ "${ZSH_VERSION-}" ]; then
  VAULT_PS1_SHELL="zsh"
elif [ "${BASH_VERSION-}" ]; then
  VAULT_PS1_SHELL="bash"
fi

_vault_ps1_init() {
  [[ -f "${VAULT_PS1_DISABLE_PATH}" ]] && VAULT_PS1_ENABLED=off
  case "${VAULT_PS1_SHELL}" in
    "zsh")
      _VAULT_PS1_OPEN_ESC="%{"
      _VAULT_PS1_CLOSE_ESC="%}"
      _VAULT_PS1_DEFAULT_BG="%k"
      _VAULT_PS1_DEFAULT_FG="%f"
      setopt PROMPT_SUBST
      autoload -U add-zsh-hook
      add-zsh-hook precmd _vault_ps1_update_cache
      ;;
    "bash")
      _VAULT_PS1_OPEN_ESC=$'\001'
      _VAULT_PS1_CLOSE_ESC=$'\002'
      _VAULT_PS1_DEFAULT_BG=$'\033[49m'
      _VAULT_PS1_DEFAULT_FG=$'\033[39m'
      [[ $PROMPT_COMMAND =~ _vault_ps1_update_cache ]] || PROMPT_COMMAND="_vault_ps1_update_cache;${PROMPT_COMMAND:-:}"
      ;;
  esac
}

_vault_ps1_color_fg() {
  local VAULT_PS1_FG_CODE
  case "${1}" in
    black) VAULT_PS1_FG_CODE=0;;
    red) VAULT_PS1_FG_CODE=1;;
    green) VAULT_PS1_FG_CODE=2;;
    yellow) VAULT_PS1_FG_CODE=3;;
    blue) VAULT_PS1_FG_CODE=4;;
    magenta) VAULT_PS1_FG_CODE=5;;
    cyan) VAULT_PS1_FG_CODE=6;;
    white) VAULT_PS1_FG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) VAULT_PS1_FG_CODE="${1}";;
    *) VAULT_PS1_FG_CODE=default
  esac

  if [[ "${VAULT_PS1_FG_CODE}" == "default" ]]; then
    VAULT_PS1_FG_CODE="${_VAULT_PS1_DEFAULT_FG}"
    return
  elif [[ "${VAULT_PS1_SHELL}" == "zsh" ]]; then
    VAULT_PS1_FG_CODE="%F{$VAULT_PS1_FG_CODE}"
  elif [[ "${VAULT_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      VAULT_PS1_FG_CODE="$(tput setaf ${VAULT_PS1_FG_CODE})"
    elif [[ $VAULT_PS1_FG_CODE -ge 0 ]] && [[ $VAULT_PS1_FG_CODE -le 256 ]]; then
      VAULT_PS1_FG_CODE="\033[38;5;${VAULT_PS1_FG_CODE}m"
    else
      VAULT_PS1_FG_CODE="${_VAULT_PS1_DEFAULT_FG}"
    fi
  fi
  echo ${_VAULT_PS1_OPEN_ESC}${VAULT_PS1_FG_CODE}${_VAULT_PS1_CLOSE_ESC}
}

_vault_ps1_color_bg() {
  local VAULT_PS1_BG_CODE
  case "${1}" in
    black) VAULT_PS1_BG_CODE=0;;
    red) VAULT_PS1_BG_CODE=1;;
    green) VAULT_PS1_BG_CODE=2;;
    yellow) VAULT_PS1_BG_CODE=3;;
    blue) VAULT_PS1_BG_CODE=4;;
    magenta) VAULT_PS1_BG_CODE=5;;
    cyan) VAULT_PS1_BG_CODE=6;;
    white) VAULT_PS1_BG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) VAULT_PS1_BG_CODE="${1}";;
    *) VAULT_PS1_BG_CODE=$'\033[0m';;
  esac

  if [[ "${VAULT_PS1_BG_CODE}" == "default" ]]; then
    VAULT_PS1_FG_CODE="${_VAULT_PS1_DEFAULT_BG}"
    return
  elif [[ "${VAULT_PS1_SHELL}" == "zsh" ]]; then
    VAULT_PS1_BG_CODE="%K{$VAULT_PS1_BG_CODE}"
  elif [[ "${VAULT_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      VAULT_PS1_BG_CODE="$(tput setab ${VAULT_PS1_BG_CODE})"
    elif [[ $VAULT_PS1_BG_CODE -ge 0 ]] && [[ $VAULT_PS1_BG_CODE -le 256 ]]; then
      VAULT_PS1_BG_CODE="\033[48;5;${VAULT_PS1_BG_CODE}m"
    else
      VAULT_PS1_BG_CODE="${DEFAULT_BG}"
    fi
  fi
  echo ${OPEN_ESC}${VAULT_PS1_BG_CODE}${CLOSE_ESC}
}

_vault_ps1_symbol() {
  [[ "${VAULT_PS1_SYMBOL_ENABLE}" == false ]] && return

  case "${VAULT_PS1_SHELL}" in
    bash)
      if ((BASH_VERSINFO[0] >= 4)) && [[ $'\u2388' != "\\u2388" ]]; then
        VAULT_PS1_SYMBOL="${VAULT_PS1_SYMBOL_DEFAULT}"
        VAULT_PS1_SYMBOL_IMG=$'\u25bc\ufe0f'
      else
        VAULT_PS1_SYMBOL=$'\xE2\x8E\x88'
        VAULT_PS1_SYMBOL_IMG=$'\xE2\x98\xB8'
      fi
      ;;
    zsh)
      VAULT_PS1_SYMBOL="${VAULT_PS1_SYMBOL_DEFAULT}"
      VAULT_PS1_SYMBOL_IMG="\u25bc";;
    *)
      VAULT_PS1_SYMBOL="Vault"
  esac

  if [[ "${VAULT_PS1_SYMBOL_USE_IMG}" == true ]]; then
    VAULT_PS1_SYMBOL="${VAULT_PS1_SYMBOL_IMG}"
  fi

  if [[ "${VAULT_PS1_SYMBOL_PADDING}" == true ]]; then
    echo "${VAULT_PS1_SYMBOL} "
  else
    echo "${VAULT_PS1_SYMBOL}"
  fi

}
trim_scheme() {
 if [[ "${VAULT_PS1_TRIM_SCHEME}" == true ]]; then
    # Remove any scheme
    echo "${1#*://}"
  else
    echo "$1"
  fi
}

_vault_ps1_update_cache() {
  local return_code=$?

  [[ "${VAULT_PS1_ENABLED}" == "off" ]] && return $return_code

  VAULT_PS1_ADDR=$(trim_scheme $VAULT_ADDR)
  return
}

# Set vault-ps1 shell defaults
_vault_ps1_init

_vaulton_usage() {
  cat <<"EOF"
Toggle vault-ps1 prompt on

Usage: vaulton [-g | --global] [-h | --help]

With no arguments, turn off vault-ps1 status for this shell instance (default).

  -g --global  turn on vault-ps1 status globally
  -h --help    print this message
EOF
}

_vaultoff_usage() {
  cat <<"EOF"
Toggle vault-ps1 prompt off

Usage: vaultoff [-g | --global] [-h | --help]

With no arguments, turn off vault-ps1 status for this shell instance (default).

  -g --global turn off vault-ps1 status globally
  -h --help   print this message
EOF
}

vaulton() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _vaulton_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    rm -f -- "${VAULT_PS1_DISABLE_PATH}"
  elif [[ "$#" -ne 0 ]]; then
    echo -e "error: unrecognized flag ${1}\\n"
    _vaulton_usage
    return
  fi

  VAULT_PS1_ENABLED=on
}

vaultoff() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _vaultoff_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    mkdir -p -- "$(dirname "${VAULT_PS1_DISABLE_PATH}")"
    touch -- "${VAULT_PS1_DISABLE_PATH}"
  elif [[ $# -ne 0 ]]; then
    echo "error: unrecognized flag ${1}" >&2
    _vaultoff_usage
    return
  fi

  VAULT_PS1_ENABLED=off
}

# Build our prompt
vault_ps1(){
  [[ "${VAULT_PS1_ENABLED}" == "off" ]] && return

  local VAULT_PS1
  local VAULT_PS1_RESET_COLOR="${_VAULT_PS1_OPEN_ESC}${_VAULT_PS1_DEFAULT_FG}${_VAULT_PS1_CLOSE_ESC}"

  # Background Color
  [[ -n "${VAULT_PS1_BG_COLOR}" ]] && VAULT_PS1+="$(_vault_ps1_color_bg ${VAULT_PS1_BG_COLOR})"

  # Prefix
  if [[ -z "${VAULT_PS1_PREFIX_COLOR:-}" ]] && [[ -n "${VAULT_PS1_PREFIX}" ]]; then
      VAULT_PS1+="${VAULT_PS1_PREFIX}"
  else
      VAULT_PS1+="$(_vault_ps1_color_fg $VAULT_PS1_PREFIX_COLOR)${VAULT_PS1_PREFIX}${VAULT_PS1_RESET_COLOR}"
  fi

  # Symbol
  VAULT_PS1+="$(_vault_ps1_color_fg $VAULT_PS1_SYMBOL_COLOR)$(_vault_ps1_symbol)${VAULT_PS1_RESET_COLOR}"

  if [[ -n "${VAULT_PS1_SEPARATOR}" ]] && [[ "${VAULT_PS1_SYMBOL_ENABLE}" == true ]]; then
    VAULT_PS1+="${VAULT_PS1_SEPARATOR}"
  fi

  # Address
  VAULT_PS1+="$(_vault_ps1_color_fg $VAULT_PS1_ADDR_COLOR)${VAULT_PS1_ADDR}${VAULT_PS1_RESET_COLOR}"


  # Suffix
  if [[ -z "${VAULT_PS1_SUFFIX_COLOR:-}" ]] && [[ -n "${VAULT_PS1_SUFFIX}" ]]; then
      VAULT_PS1+="${VAULT_PS1_SUFFIX}"
  else
      VAULT_PS1+="$(_vault_ps1_color_fg $VAULT_PS1_SUFFIX_COLOR)${VAULT_PS1_SUFFIX}${VAULT_PS1_RESET_COLOR}"
  fi

  # Close Background color if defined
  [[ -n "${VAULT_PS1_BG_COLOR}" ]] && VAULT_PS1+="${_VAULT_PS1_OPEN_ESC}${_VAULT_PS1_DEFAULT_BG}${_VAULT_PS1_CLOSE_ESC}"

  echo "${VAULT_PS1}"
}
