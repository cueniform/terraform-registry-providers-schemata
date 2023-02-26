package processor

import (
	"cueniform.com/internal/processor/translator"
)

input: {
	schema: {...}
	params: {
		registry:  *"registry.terraform.io" | string @tag(registry)
		namespace: string                            @tag(namespace)
		provider:  string                            @tag(provider)
	}
	path: "\(params.registry)/\(params.namespace)/\(params.provider)"
}

output: {
	provider: {translator & {#Terraform: input.schema.provider_schemas[input.path].provider}}.#JSON
}
