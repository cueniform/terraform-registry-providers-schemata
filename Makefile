.DEFAULT_GOAL:=fail-because-no-goal-specified
SHELL:=/bin/bash -euo pipefail
SUCCESS=\# ✅ $@ ✅

.PHONY: test
test: test_fixtures
	$(SUCCESS)

.PHONY: test_fixtures
test_fixtures:
	./bin/test-fixtures.sh
	$(SUCCESS)
