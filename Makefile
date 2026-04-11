SHELL := /bin/zsh
.PHONY: setup update check validate test test-vm cleanup help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Full bootstrap from scratch (setup.sh)
	./setup.sh

update: ## Update packages and re-run playbook
	brew update
	. ~/.zshenv && ansible-playbook setup.yml --ask-become-pass

cleanup: ## Detect unmanaged packages and offer to add/remove them
	./setup.sh --cleanup

check: ## Dry-run: show what would change without applying
	. ~/.zshenv && ansible-playbook setup.yml --check --diff

validate: ## Quick validation of tools, configs, symlinks, and env vars
	@bash scripts/validate.sh

test: validate ## Local test: validate + Ansible syntax check
	@echo ""
	@echo "Ansible syntax check..."
	@ansible-playbook setup.yml --syntax-check
	@echo ""
	@echo "All local tests passed."

test-vm: ## Full end-to-end test in a clean Tart macOS VM
	./scripts/tart-test.sh

test-vm-debug: ## Same as test-vm but keeps VM alive for debugging
	./scripts/tart-test.sh --keep
