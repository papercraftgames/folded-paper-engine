class_name StringUtils

static func parse_csv_string(group_string: String) -> Array[String]:
	var raw_parts := group_string.split(",")
	var groups: Array[String] = []
	
	for p in raw_parts:
		var clean_part := p.trim_prefix(" ").trim_suffix(" ")
		
		groups.append(clean_part)
	
	return groups
