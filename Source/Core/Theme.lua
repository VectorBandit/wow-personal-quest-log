PQLTheme = {
	colors = {
		Bit = {
			text = {0.98, 0.984, 0.965, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		CandyPop = {
			text = {0.933, 0.749, 0.961, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		GameBoy = {
			text = {0.957, 0.961, 0.914, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		Lackluster = {
			text = {1, 1, 1, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		LacklusterCarrot = {
			text = {1, 1, 1, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		LacklusterLime = {
			text = {1, 1, 1, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		LacklusterSky = {
			text = {1, 1, 1, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		Minimal = {
			text = {1, 1, 1, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
		Slurry = {
			text = {1, 1, 0.78, 1},
			positive = {0.584, 0.937, 0.6, 1},
			negative = {0.937, 0.584, 0.635, 1},
		},
	}
}

function PQLTheme:Color(name)
	return unpack(PQLTheme.colors[PQL.DATA:Get("theme")][name] or nil)
end

function PQLTheme:ColorTable(name)
	return PQLTheme.colors[PQL.DATA:Get("theme")][name] or nil
end

