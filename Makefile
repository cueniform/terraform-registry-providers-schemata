.DEFAULT_GOAL:=fail-because-no-goal-specified
SHELL:=/bin/bash -euo pipefail

.PHONY: test
test: test_fixtures

.PHONY: test_fixtures
test_fixtures:
	./tests/test-fixtures.sh
	## SUCCESS
