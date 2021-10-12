data:extend({
	{
		type = "string-setting",
		name = "Remove Chests",
		setting_type = "runtime-global",
		default_value = "If Empty",
		allow_blank = false,
		auto_trim = true,
		allowed_values = {
			"No",
			"If Empty",
			"Yes"
		},
		order = "deconstruction_a"
	},
	{
		type = "bool-setting",
		name = "Remove Belts",
		setting_type = "runtime-global",
		default_value = false,
		order = "deconstruction_b"
	}
})