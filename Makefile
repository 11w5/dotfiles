.PHONY: help bootstrap restow packages csv full ssh audit update uninstall adopt

PKGS := bash zsh starship tmux nvim ranger scripts dev git editor
STOW := stow -d stow -t $(HOME)

help:
	@echo "Targets:"
	@echo "  make bootstrap   - stow link dotfiles"
	@echo "  make restow      - restow $(PKGS)"
	@echo "  make packages    - install packages from packages/* (apt/brew + pipx/npm/cargo)"
	@echo "  make csv         - install duckdb, xsv (best-effort), csvview"
	@echo "  make full        - bootstrap + packages + csv"
	@echo "  make ssh         - test/configure GitHub SSH using a loaded agent key"
	@echo "  make audit       - run local security audit"
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

audit:
	bash scripts/security_audit.sh

update:
	git pull --ff-only
	$(STOW) -R $(PKGS)

uninstall:
	$(STOW) -D $(PKGS)

adopt:
	bash scripts/stow_adopt.sh $(PKGS)
