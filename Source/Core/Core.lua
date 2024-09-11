local LibDB = LibStub("LibDataBroker-1.1")
local LibIcon = LibStub("LibDBIcon-1.0")

PQL_Core = {}

function PQL_Core:Init()
    PQL_Core:RegisterMinimapButton()
    PQL_Core:RegisterSlashCommands()

    -- Initialize panels.
    PQL.main:FactoryInit()
end

function PQL_Core:RegisterMinimapButton()
    local dataObject = LibDB:NewDataObject("PersonalQuestLog", {
        icon = PQLPath("Art\\Icon.png"),
        text = "Personal Quest Log",
        type = "launcher",
        OnClick = function() PQL:Toggle() end,
        OnTooltipShow = function(t) t:AddLine("Personal Quest Log") end
    })

    LibIcon:Register("PersonalQuestLog", dataObject, {hide = false})
end

function PQL_Core:RegisterSlashCommands()
    PQL:RegisterChatCommand("pql", "OnSlashCommand")
    PQL:RegisterChatCommand("personalquestlog", "OnSlashCommand")
end

function PQL_Core:OnSlashCommand(input)
    if not input then
        input = ""
    end

    input = input:trim()

    if input == "" then
        PQL:Toggle()
    elseif input == "settings" then
        Settings.OpenToCategory("Personal Quest Log")
    else
        self:Print("Available commands:")
        self:Print("/pql settings")
    end
end

function PQL_Core:CheckGoalsCompletion()
	local goals = PQL_DB.Goals:GetClean()

	for _, goal in pairs(goals) do
		local isCompleted = goal.isCompleted or false
		local details = goal.goalDetails or {}
		local requiredCount = tonumber(details.requiredCount) or 0

		-- Goal Type: Item OR Currency
		if goal.goalType == 2 or goal.goalType == 3 then
			local currentCount = goal.goalType == 2 and
				PQL_Data.Items:GetCount(details.resourceId) or
				PQL_Data.Currencies:GetCount(details.resourceId)

			goal.goalDetails.currentCount = currentCount
			isCompleted = requiredCount and currentCount and requiredCount > 0 and currentCount >= requiredCount
		end

		-- Set completion status, but only if it has changed.
		if goal.isCompleted ~= isCompleted then
			PQL_DB.Goals:Update(goal.goalId, "isCompleted", isCompleted)
		end
	end
end

