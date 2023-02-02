# terraform-registry-schema-cuelang

This repository holds CUE schemas describing the configuration structures expected by various [Providers](https://developer.hashicorp.com/terraform/language/providers) published on the [Terraform Registry](https://registry.terraform.io).

These files are designed and intended for use with [Cueniform](https://www.cueniform.com), but you're welcome to use them to validate your Terraform configurations independently, without using that tool, by invoking CUE directly.

This document describes the process of using these definitions to validate Terraform configurations manually, without [Cueniform](https://www.cueniform.com). If you're using Cueniform, please refer instead to [its documentation](https://www.cueniform.com/docs).

## Validating a Terraform configuration

1. Instantiate a CUE module with `cue mod init`.
1. Clone this repo into `cue.mod/pkg/cueniform.com/x/registry.terraform.io/` via its canonical git URL (`https://cueniform.com/x/registry.terraform.io`):
   ```
   $ git clone \
       https://cueniform.com/x/registry.terraform.io \
       cue.mod/pkg/cueniform.com/x/registry.terraform.io/
   ```
1. Translate your HCL-based Terraform configuration into a single `.tf.json` file containing its [JSON equivalent](https://developer.hashicorp.com/terraform/language/syntax/json).
   - Tools like [hcl2json](https://github.com/tmccombs/hcl2json) and [hcldec](https://github.com/hashicorp/hcl/tree/main/cmd/hcldec) can help with automating this process, but their output can be overly cautious e.g. with structs being [superfluously wrapped in lists](https://github.com/tmccombs/hcl2json/issues/21).
1. Identify which versions of which providers your configuration uses.
   - Hint: check the `provider_selections` section displayed by `terraform version -json`
1. Identify the resource types and data-source types your configuration uses.
   - Hint: inside your merged .tf.json configuration, these will be the top-level keys *under* the `resources` and `data` keys.
1. For each unique combination of the following facets present in your configuration:
   - provider "NAMESPACE" (e.g. `hashicorp`)
   - provider "NAME" (e.g. `aws`)
   - provider "VERSION" (e.g. `4.50.0`)
   - resource or data-source "TYPE" (e.g. `instance`)

... run the following:

```
$ cue vet -c \
    cueniform.com/x/registry.terraform.io/providers/[NAMESPACE]/[NAME]/[VERSION]/(resource|data-source)/[TYPE] \
    your-config.tf.json
```

Any incorrectly-specified resources or data-sources will result in a CUE evaluation error.
