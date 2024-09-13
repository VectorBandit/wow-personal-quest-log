PQL.THEME = {
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
	}
}

function PQL.THEME:Color(name)
	return unpack(PQL.THEME.colors[PQL.DATA:Get("theme")][name] or nil)
end

function PQL.THEME:ColorTable(name)
	return PQL.THEME.colors[PQL.DATA:Get("theme")][name] or nil
end
