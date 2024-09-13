local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local m = PQL:NewModule("Options_Global", "AceConsole-3.0")

function m:OnInitialize()
	local options = {
		name = "Personal Quest Log",
		handler = m,
		type = "group",
		args = {
			generalGroup = {
				name = "General",
				type = "group",
				order = 1,
				args = {
					showGoalsInTooltip = {
						name = "Show goals in tooltip",
						type = "toggle",
						set = "SetShowGoalsInTooltip",
						get = "GetShowGoalsInTooltip",
						order = 1
					},
				}
			},
			appearanceGroup = {
				name = "Appearance",
				type = "group",
				order = 2,
				args = {
					theme = {
						name = "Theme",
						type = "select",
						values = {
							Bit = "Bit",
							CandyPop = "Candy Pop",
							GameBoy = "GameBoy",
							Lackluster = "Lackluster",
						},
						set = "SetThemeOption",
						get = "GetThemeOption",
						style = "dropdown",
						order = 1
					},
					themeDescription = {
						name = "A UI reload is required to apply a new theme.",
						type = "description",
						fontSize = "medium",
						order = 2
					},
				}
			},
			profilesGroup = AceDBOptions:GetOptionsTable(PQL.DATA.db)
		}
	}

    AceConfig:RegisterOptionsTable("PQL_Options_Global", options)
    AceConfigDialog:AddToBlizOptions("PQL_Options_Global", "Personal Quest Log")
end

-- The methods below are used to update each option.

function m:SetShowGoalsInTooltip(_, value)
	PQL.DATA:Set("showGoalsInTooltip", value)
end

function m:GetShowGoalsInTooltip()
	return PQL.DATA:Get("showGoalsInTooltip")
end

function m:SetThemeOption(_, value)
	PQL.DATA:Set("theme", value)
end

function m:GetThemeOption()
    return PQL.DATA:Get("theme")
end

