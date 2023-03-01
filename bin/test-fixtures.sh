#!/usr/bin/env bash
set -euo pipefail
#set -x

test_dir=tests/tmp
mkdir -p "$test_dir"

for fixture in tests/fixtures/*; do
    # Clean up after previous test, if any
    find "$test_dir"/ -type f -not -name .gitkeep -delete

    # Turn the fixture into multiple CUE files
    ./bin/tf-schema-to-cue.sh "$fixture"/input.schema.json cueniTEST fixture "$test_dir"

    # Vet all schemas against test cases
    ## Find all schemas
    export schemas=$(find "$test_dir"/ -type f -name 'schema.cue') # FIXME: we're using cue's file mode here

    ## Positive tests
    ( shopt -s nullglob; set -x
        cue vet $schemas $fixture/accepts/*.{yml,yaml,json}
    )

    ## Negative tests
    find $fixture/rejects/ -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.json' \) -print0 \
    | xargs -r -I{} -0 bash -c \
      "{ PS4=\"${PS4}! \"; set -x; ! cue vet $schemas {} 2>/dev/null; } || { echo 'FAIL: did not reject {}'; exit 1; }"
done

find "$test_dir"/ -type f -not -name .gitkeep -delete
