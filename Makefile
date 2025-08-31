.PHONY: help bootstrap restow packages csv full ssh publish update uninstall

PKGS := bash zsh tmux nvim ranger scripts dev git editor
STOW := stow -d stow -t $(HOME)

help:
	@echo "Targets:"
	@echo "  make bootstrap   - stow link dotfiles"
	@echo "  make restow      - restow $(PKGS)"
	@echo "  make packages    - install packages from packages/* (apt/brew + pipx/npm/cargo)"
	@echo "  make csv         - install duckdb, xsv (best-effort), csvview"
	@echo "  make full        - bootstrap + packages + csv"
	@echo "  make ssh         - generate SSH key, upload to GitHub, set origin to SSH"
	@echo "  make publish     - create/push GitHub repo (token flow)"
	@echo "  make update      - git pull + restow"
	@echo "  make uninstall   - destow $(PKGS)"

bootstrap:
	bash scripts/bootstrap_stow.sh

restow:
	$(STOW) -R $(PKGS)

packages:
	bash scripts/install_packages.sh

csv:
	bash scripts/install_csv_tools.sh

full: bootstrap packages csv

ssh:
	bash scripts/setup_ssh_github.sh

publish:
	@if [ -x scripts/github_fix_remote_push.sh ]; then \
	  bash scripts/github_fix_remote_push.sh || true; \
	fi; \
	if [ -x scripts/github_publish_token.sh ]; then \
	  bash scripts/github_publish_token.sh || true; \
	fi

update:
	git pull --rebase || true
	$(STOW) -R $(PKGS)

uninstall:
	$(STOW) -D $(PKGS)

adopt:
	bash scripts/stow_adopt.sh $(PKGS)
