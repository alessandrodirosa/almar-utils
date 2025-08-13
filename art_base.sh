#!/bin/sh

# --- ASCII ART BASE PATH ---
# This script assumes a directory named 'ascii-art' exists in the same location,
# containing 'base.txt' and 'flatpak.txt'.
ASCII_ART_BASE_PATH="ascii-art"

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m' # New color for ASCII art
BOLD='\033[1m'
NC='\033[0m' # No Color

# Clear the terminal screen for a better visual effect
clear

# Print the ASCII art title from external files
# Note: The script will fail if the files/directory are not found.
if [ -d "$ASCII_ART_BASE_PATH" ]; then
    echo -e "${MAGENTA}"
    cat "${ASCII_ART_BASE_PATH}/base.txt"
    cat "${ASCII_ART_BASE_PATH}/$@.txt"
    echo -e "${NC}"
else
    echo -e "${RED}Warning: ASCII art directory not found at '${ASCII_ART_BASE_PATH}'.${NC}"
fi