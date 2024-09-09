local AceAddon = LibStub("AceAddon-3.0")

BINDING_HEADER_PQL = "Personal Quest Log"
BINDING_NAME_PQL_TOGGLE = "Show/Hide Personal Quest Log"

PQL_THEME = {
    {0.984, 0.961, 0.937, 1},
    {0.949, 0.827, 0.671, 1},
    {0.776, 0.624, 0.647, 1},
    {0.545, 0.427, 0.612, 1},
    {0.286, 0.302, 0.494, 1},
    {0.153, 0.153, 0.267, 1},
    invalid = {0.937, 0.584, 0.635, 1},
	valid = {0.584, 0.937, 0.6, 1}
}

PQL = AceAddon:NewAddon("PQL", "AceConsole-3.0")
PQL._listeners = {}
PQL._focusedEditBox = nil

function PQL:OnInitialize()
    PQL_DB:Init()
    PQL_Core:Init()

    -- self:SetupDebuggingTools()

    self.confirmationPopup:Init()
	self.dropdown:Init()

    -- Small forwarding for modified click on items.
    hooksecurefunc("HandleModifiedItemClick", function(itemLink, a, b, c)
		if IsShiftKeyDown() and not IsControlKeyDown() then
			local itemId = select(3, strfind(itemLink, "item:(%d+)"))

			if PQL._focusedEditBox and PQL._focusedEditBox.OnModifiedItemClick then
				PQL._focusedEditBox.OnModifiedItemClick(itemId, itemLink)
			end

			self:Fire("ModifiedItemClick", tonumber(itemId))
		end
    end)

	-- Create a placeholder frame for handling some global data.
	self.ph = CreateFrame("Frame", nil, UIParent)

	-- Register all events we are planning to handle globally in some way.
	self.ph:RegisterEvent("MERCHANT_SHOW")
	self.ph:RegisterEvent("MERCHANT_CLOSED")
	self.ph:RegisterEvent("MERCHANT_UPDATE")
	self.ph:RegisterEvent("BAG_UPDATE")
	self.ph:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self.ph:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	self.ph:RegisterEvent("GET_ITEM_INFO_RECEIVED")

	self.ph:SetScript("OnEvent", function(_, event, arg1, arg2)
		-- Store merchant items when a store is opened.
		if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
			PQL_Data.Merchant:Update()

		-- Bag items or currency have changed. Update the quest list.
		elseif event == "BAG_UPDATE" or event == "CURRENCY_DISPLAY_UPDATE" then
			self.main:Update()

		-- Item info received (async response).
		elseif event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
			PQL_Data.Items:_RunGetCallbacks(arg1, arg2)
		end
	end)
end

function PQL:OnSlashCommand(input)
    PQL_Core:OnSlashCommand(input)
end

function PQL:Toggle()
    PQL.main:Toggle()
end

function PQL:SetupDebuggingTools()
    PQL.reloadButton = PQLFactory.Button:CreateButton(UIParent, {
        width = 100,
        text = "Reload",
        anchor = { "TOP", UIParent, "TOP", 0, -10 },
        callback = function() ReloadUI() end
    })
end

function PQL:On(event, callback)
    if not self._listeners[event] then
        self._listeners[event] = {}
    end

    table.insert(self._listeners[event], callback)
end

function PQL:Fire(event, data)
    if self._listeners[event] then
        for _, callback in ipairs(self._listeners[event]) do
            callback(data)
        end
    end
end
