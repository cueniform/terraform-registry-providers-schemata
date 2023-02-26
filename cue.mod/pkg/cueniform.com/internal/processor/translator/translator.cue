package translator

#Terraform: #Schema

#Schema: {
	version: int
	block:   #Block
}

#Block: {
	description_kind?: "plain"
}

#JSON: {
	type: "object"
	properties: {
		wibble: type: "string"
	}
	additionalProperties: false
	required: []
}
