# -----------------------------------------------------------------------------
# virtualenv-path-hook.zsh
# A Zsh plugin that reacts to Python virtualenv changes.
#
# When $VIRTUAL_ENV changes:
#   - If pyvenv.cfg exists and include-system-site-packages = true,
#     append its 'home' path to the original system PATH.
#   - Restores the original PATH on deactivate or env change.
#
# Author: crower-style version by ChatGPT
# -----------------------------------------------------------------------------

# Ensure we have add-zsh-hook
autoload -Uz add-zsh-hook

# -----------------------------------------------------------------------------
# Preserve the original PATH
# -----------------------------------------------------------------------------
if [[ -z "$__VENV_ORIGINAL_PATH" ]]; then
  export __VENV_ORIGINAL_PATH="$PATH"
fi

# -----------------------------------------------------------------------------
# Internal state
# -----------------------------------------------------------------------------
typeset -g __VENV_LAST_PATH=""
typeset -g __VENV_LAST_VIRTUAL_ENV=""

# -----------------------------------------------------------------------------
# Read a key=value from pyvenv.cfg
# -----------------------------------------------------------------------------
__venv_read_cfg() {
  local cfg="$1"
  local key="$2"
  awk -F' = ' -v key="$key" '$1 == key {print $2}' "$cfg" 2>/dev/null
}

# -----------------------------------------------------------------------------
# React when VIRTUAL_ENV changes
# -----------------------------------------------------------------------------
__venv_on_change() {
  local old="$1"
  local new="$2"

  # Always reset PATH to original baseline
  export PATH="$__VENV_ORIGINAL_PATH"

  if [[ -n "$new" && -d "$new" ]]; then
    local cfg="$new/pyvenv.cfg"
    if [[ -f "$cfg" ]]; then
      local include_system
      include_system=$(__venv_read_cfg "$cfg" "include-system-site-packages")
      include_system=${include_system//[[:space:]]/}

      if [[ "$include_system" == "true" ]]; then
        local home_dir
        home_dir=$(__venv_read_cfg "$cfg" "home")
        home_dir=${home_dir//[[:space:]]/}
        if [[ -d "$home_dir" ]]; then
          export PATH="$PATH:$home_dir"
          print -P "%F{green}✅ include-system-site-packages=true → appended '$home_dir' to PATH%f"
        fi
      fi
    fi
  fi
}

# -----------------------------------------------------------------------------
# Hook function run before each prompt
# -----------------------------------------------------------------------------
__venv_precmd_hook() {
  if [[ "$VIRTUAL_ENV" != "$__VENV_LAST_VIRTUAL_ENV" ]]; then
    __venv_on_change "$__VENV_LAST_VIRTUAL_ENV" "$VIRTUAL_ENV"
    __VENV_LAST_VIRTUAL_ENV="$VIRTUAL_ENV"
  fi
}

# -----------------------------------------------------------------------------
# Register the hook
# -----------------------------------------------------------------------------
add-zsh-hook precmd __venv_precmd_hook
