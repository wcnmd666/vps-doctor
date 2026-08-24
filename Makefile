.PHONY: test syntax lint package

SHELL_FILES := bin/vps-doctor install.sh uninstall.sh $(wildcard lib/*.sh checks/*.sh fixes/*.sh tests/*.sh)

syntax:
	bash -n $(SHELL_FILES)

test: syntax
	bash tests/run.sh

lint:
	shellcheck -x $(SHELL_FILES)

package: test
	bash scripts/package.sh
