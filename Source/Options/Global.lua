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
			appearanceGroup = {
				name = "Appearance",
				type = "group",
				args = {
					theme = {
						name = "Theme",
						type = "select",
						values = {
							Bit = "Bit",
							CandyPop = "Candy Pop",
							GameBoy = "GameBoy",
							Lackluster = "Lackluster",
							LacklusterCarrot = "Lackluster - Carrot",
							LacklusterLime = "Lackluster - Lime",
							LacklusterSky = "Lackluster - Sky",
							Minimal = "Minimal",
							Slurry = "Slurry",
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
			profilesGroup = AceDBOptions:GetOptionsTable(PQL.db)
		}
	}

    AceConfig:RegisterOptionsTable("PQL_Options_Global", options)
    AceConfigDialog:AddToBlizOptions("PQL_Options_Global", "Personal Quest Log")
end

-- The methods below are used to update each option.

function m:SetDebugOption(_, value)
    PQL.db.profile.debug = value
end

function m:GetDebugOption(_)
    return PQL.db.profile.debug
end

function m:SetThemeOption(_, value)
    PQL.db.profile.theme = value
end

function m:GetThemeOption(_)
    return PQL.db.profile.theme
end

