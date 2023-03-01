package inventory

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
	provider: *"" | string
	if input.schema.provider_schemas[input.path].provider != _|_ {
		provider: "provider"
	}
	resources:    *"" | string
	data_sources: *"" | string
}
