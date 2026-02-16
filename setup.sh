#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  Dotfiles Bootstrap"
echo "=========================================="
echo ""

# 1. Xcode CLI tools
if ! xcode-select -p &>/dev/null; then
  echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
  xcode-select --install
  echo "Please wait for Xcode CLI tools to finish installing, then re-run this script."
  exit 1
else
  echo -e "${GREEN}✓ Xcode CLI tools installed${NC}"
fi

# 2. Homebrew
if ! command -v brew &>/dev/null; then
  echo -e "${YELLOW}Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo -e "${GREEN}✓ Homebrew installed${NC}"
fi

# 3. Ansible
if ! command -v ansible-playbook &>/dev/null; then
  echo -e "${YELLOW}Installing Ansible...${NC}"
  brew install ansible
else
  echo -e "${GREEN}✓ Ansible installed${NC}"
fi

# 4. ~/.zshenv
if [ ! -f "$HOME/.zshenv" ]; then
  echo -e "${YELLOW}Creating ~/.zshenv from example template...${NC}"
  cp "$(dirname "$0")/.zshenv.example" "$HOME/.zshenv"
  echo ""
  echo -e "${RED}ACTION REQUIRED:${NC}"
  echo "  Edit ~/.zshenv and fill in your personal values (name, email, SSH keys, etc.)"
  echo "  Then re-run this script."
  echo ""
  echo "  vim ~/.zshenv"
  exit 1
else
  echo -e "${GREEN}✓ ~/.zshenv exists${NC}"
fi

# 5. Source .zshenv
echo "Sourcing ~/.zshenv..."
source "$HOME/.zshenv"

# Verify required vars
if [ -z "$GIT_USER_NAME" ]; then
  echo -e "${RED}Error: GIT_USER_NAME is not set in ~/.zshenv${NC}"
  echo "Please edit ~/.zshenv and fill in your values."
  exit 1
fi

echo -e "${GREEN}✓ Environment variables loaded${NC}"
echo ""

# 6. Run Ansible playbook
echo "Running Ansible playbook..."
echo ""
cd "$(dirname "$0")"
ansible-playbook setup.yml

echo ""
echo -e "${GREEN}Done! Restart your terminal or run: source ~/.zshrc${NC}"
