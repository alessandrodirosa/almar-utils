#!/bin/sh

# ==============================================================================
# --- PRINTING FUNCTIONS SUITE ---
# ==============================================================================

# Prints a formatted section header.
# Usage: print_header "Your Title"
print_header() {
  echo ""
  echo -e "${CYAN}--- $1 ---${NC}"
  echo ""
}

# Prints a line of text with a specific color/attribute.
# The color parameter is optional. Defaults to standard text color.
# Usage: print_line "Your text" "$GREEN"
# Usage: print_line "Bold and red text" "${BOLD}${RED}"
# Usage: print_line "Just a normal line of text"
print_line() {
  local message="$1"
  local color="${2:-$NC}" # Default to NC (No Color) if $2 is not provided
  echo -e "${color}${message}${NC}"
}

# Prints a prompt for user input without a trailing newline.
# The color parameter is optional. Defaults to YELLOW.
# Usage: print_prompt "Your question? (Y/n) "
# Usage: print_prompt "A red question? " "$RED"
print_prompt() {
  local message="$1"
  local color="${2:-$YELLOW}" # Default to YELLOW for prompts
  printf -- "${color}%s${NC}" "$message"
}