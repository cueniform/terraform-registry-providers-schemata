#!/usr/bin/env bash
set -euo pipefail
#set -x

raw_schema_file="$1"
namespace="$2"
provider="$3"
cue_root="$4"

# Exit if cue_root contains anything other than directories
! { find "$cue_root"/ ! -type d | grep -q . ; } \
|| {
    echo "$cue_root/ isn't empty; exiting."
    exit 1
}
find "$cue_root"/ -mindepth 1 -type d -delete

# Handle being given a zstd-compressed schema file
## (we rely on the fact that zstdcat acts like 'cat' when given an uncompressed file)
tf_schema_file="$(mktemp --suffix .json)"
echo "# temp file: $tf_schema_file"
zstdcat --stdout "$raw_schema_file" \
| jq . \
>"$tf_schema_file"

# Export all the schemas that the fixture contains, and import into CUE

## The singleton "provider" schema
json_file="$cue_root"/provider/schema.json
cue_file="$(echo "$json_file" | sed 's/json$/cue/')"
mkdir -p "$(dirname "$json_file")"

cue export \
    cueniform.com/internal/processor \
    "$tf_schema_file" \
    --path       "input:schema:" \
    --inject     namespace="$namespace" \
    --inject     provider="$provider" \
    --expression "output.provider" \
    --outfile    "$json_file"

cue import \
    $json "$json_file" \
    --package "provider" \
    --path    "_#Schema:" \
    --outfile "$cue_file"

echo "provider?: ${provider}?: _#Schema | [..._#Schema]" >>"$cue_file"

cue fmt "$cue_file"

## Zero or more "resources"
### Find which resources the fixture contains
resources=$(cue export \
    cueniform.com/internal/processor:inventory \
    "$tf_schema_file" \
    --path       "input:schema:" \
    --inject     namespace="$namespace" \
    --inject     provider="$provider" \
    --expression "output.resources" \
    --out        text
)

### Export each resource's schema
for resource in $resources; do
    json_file="$cue_root"/resources/"$resource"/schema.json
    cue_file="$(echo "$json_file" | sed 's/json$/cue/')"
    mkdir -p "$(dirname "$json_file")"

    cue export \
        cueniform.com/internal/processor \
        "$tf_schema_file" \
        --path       "input:schema:" \
        --inject     namespace="$namespace" \
        --inject     provider="$provider" \
        --expression "output.resource.$resource" \
       	--outfile    "$json_file"

    cue import \
        $json "$json_file" \
        --package "$resource" \
        --path    "_#Schema:" \
        --outfile "$cue_file"

    echo "resource?: ${resource}?: [_] _#Schema" >>"$cue_file"
    cue fmt "$cue_file"
done

## Zero or more "data-sources"

### Find which data-sources the fixture contains
data_sources=$(cue export \
    cueniform.com/internal/processor:inventory \
    "$tf_schema_file" \
    --path       "input:schema:" \
    --inject     namespace="$namespace" \
    --inject     provider="$provider" \
    --expression "output.data_sources" \
    --out        text
)

### Export each data-source's schema
for data_source in $data_sources; do
    json_file="$cue_root"/data-sources/"$data_source"/schema.json
    cue_file="$(echo "$json_file" | sed 's/json$/cue/')"
    mkdir -p "$(dirname "$json_file")"

    cue export \
        cueniform.com/internal/processor \
        "$tf_schema_file" \
        --path       "input:schema:" \
        --inject     namespace="$namespace" \
        --inject     provider="$provider" \
        --expression "output.data_source.$data_source" \
       	--outfile    "$json_file"

    cue import \
        $json "$json_file" \
        --package "$data_source" \
        --path    "_#Schema:" \
        --outfile "$cue_file"

    echo "data?: ${data_source}?: [_] _#Schema" >>"$cue_file"
    cue fmt "$cue_file"
done

rm "$tf_schema_file"
