local AceDB = LibStub("AceDB-3.0")

PQL.DATA = {
	DEFAULT_DB = {
		profile = {
			seenHelp = false,
			seenGroupDrawerHelp = false,
			seenQuestDrawerHelp = false,
			theme = "Lackluster",
			showGoalsInTooltip = true,
		}
	},
	listeners = {},
}

function PQL.DATA:Init()
    self.db = AceDB:New("PersonalQuestLogDB", self.DEFAULT_DB, true)

	-- V2 fix
	PQL.DATA.GROUPS:_ApplyV2Fix()
	PQL.DATA.QUESTS:_ApplyV2Fix()
	PQL.DATA.GOALS:_ApplyV2Fix()
end

function PQL.DATA:Get(key)
	return self.db.profile[key]
end

function PQL.DATA:Set(key, value)
	self.db.profile[key] = value
end

function PQL.DATA:On(events, callback)
	if type(events) == "string" then
		events = {events}
	end

	for _, event in ipairs(events) do
		if not self.listeners[event] then
			self.listeners[event] = {}
		end

		table.insert(self.listeners[event], callback)
	end
end

function PQL.DATA:Fire(event, ...)
    if self.listeners[event] then
        for _, callback in ipairs(self.listeners[event]) do
            callback(event, ...)
        end
    end
end

