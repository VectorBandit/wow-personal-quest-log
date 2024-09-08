local AceDB = LibStub("AceDB-3.0")

-- The main database for storing everything.
PQL_DB_INITIAL_DATABASE = {
    profile = {
		seenHelp = false,
		seenGroupDrawerHelp = false,
		seenQuestDrawerHelp = false,
		theme = "Lackluster"
    }
}

PQL_DB = {
    _listeners = {}
}

function PQL_DB:Init()
    PQL.db = AceDB:New("PersonalQuestLogDB", PQL_DB_INITIAL_DATABASE, true)
end

-- Events

function PQL_DB:On(events, callback)
	if type(events) == "string" then
		events = {events}
	end

	for _, event in ipairs(events) do
		if not PQL_DB._listeners[event] then
			PQL_DB._listeners[event] = {}
		end

		table.insert(PQL_DB._listeners[event], callback)
	end
end

function PQL_DB:Off(event, callback)
	if PQL_DB._listeners[event] then
		local newListeners = {}

		for _, cb in ipairs(PQL_DB._listeners[event]) do
			if cb ~= callback then
				table.insert(newListeners, cb)
			end
		end

		PQL_DB._listeners[event] = newListeners
	end
end

function PQL_DB:Fire(event, data)
    if PQL_DB._listeners[event] then
        for _, callback in ipairs(PQL_DB._listeners[event]) do
            callback(data)
        end
    end
end
