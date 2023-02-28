#!/usr/bin/env bash
set -euo pipefail
#set -x

for fixture in tests/fixtures/*; do
    # Clean up after previous test, if any
    find tests/tmp/ -type f -not -name .gitkeep -delete

    # Export all the schemas that the fixture contains, and import into CUE

    ## The singleton "provider" schema
    cue export \
        cueniform.com/internal/processor \
        $fixture/input.schema.json \
        --path input:schema: \
        --inject namespace=cueniTEST \
        --inject provider=fixture \
        --expression output.provider \
        --outfile tests/tmp/provider.schema.json
    cue import $json tests/tmp/provider.schema.json --package provider --path '_#Schema:'
    echo "provider: fixture: _#Schema | [..._#Schema]" >>tests/tmp/provider.schema.cue # FIXME: this is awful

    ## Zero or more "resources"

    ### Find which resources the fixture contains
    cue export \
        cueniform.com/internal/processor:inventory \
        $fixture/input.schema.json \
        --path input:schema: \
        --inject namespace=cueniTEST \
        --inject provider=fixture \
        --expression output.resources \
        --outfile tests/tmp/inventory.resources.txt

    ### Export each resource's schema
    for resource in $(cat tests/tmp/inventory.resources.txt); do
        cue export \
            cueniform.com/internal/processor \
            $fixture/input.schema.json \
            --path input:schema: \
            --inject namespace=cueniTEST \
            --inject provider=fixture \
            --expression output.resource.$resource \
           	--outfile tests/tmp/resources/$resource.schema.json
        cue import $json tests/tmp/resources/$resource.schema.json --package $resource
    done

    ## Zero or more "data-sources"

    ### Find which data-sources the fixture contains
    cue export \
        cueniform.com/internal/processor:inventory \
        $fixture/input.schema.json \
        --path input:schema: \
        --inject namespace=cueniTEST \
        --inject provider=fixture \
        --expression 'output."data-sources"' \
        --outfile tests/tmp/inventory.data-sources.txt

    ### Export each data-source's schema
    for data_source in $(cat tests/tmp/inventory.data-sources.txt); do
        cue export \
            cueniform.com/internal/processor \
            $fixture/input.schema.json \
            --path input:schema: \
            --inject namespace=cueniTEST \
            --inject provider=fixture \
            --expression "output.\"data-source\".$data_source" \
           	--outfile tests/tmp/data-sources/$data_source.schema.json
        cue import $json tests/tmp/data-sources/$data_source.schema.json --package $data_source
    done

    # Vet all schemas against test cases
    export schemas=$(find tests/tmp/ -type f -name '*.schema.cue')

    ## Positive tests
    shopt -s nullglob
    cue vet $schemas $fixture/accepts/*.{yml,yaml,json}
    shopt -u nullglob

    ## Negative tests
    find $fixture/rejects/ -print0 -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.json' \) \
    | xargs -r -I{} -0 bash -c \
      "{ ! cue vet $schemas {} 2>/dev/null; } || { echo 'FAIL: did not reject {}'; exit 1; }"
done

find tests/tmp/ -type f -not -name .gitkeep -delete
