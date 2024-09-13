local AceAddon = LibStub("AceAddon-3.0")
local LibDB = LibStub("LibDataBroker-1.1")
local LibIcon = LibStub("LibDBIcon-1.0")

BINDING_HEADER_PQL = "Personal Quest Log"
BINDING_NAME_PQL_TOGGLE = "Show/Hide Personal Quest Log"

PQL = AceAddon:NewAddon("PQL", "AceConsole-3.0")
PQL.eventListeners = {}
PQL.focusedEditBox = nil

PQL.ENTITY = {}
PQL.FACTORY = {}

function PQL:OnInitialize()
	self.DATA:Init()
	self.GOALS:Init()

    self.main:FactoryInit()
    self.confirmPopup:Init()
	self.dropdown:Init()

    self:SetupDebuggingTools()

    -- Forward modified item clicks.
    hooksecurefunc("HandleModifiedItemClick", function(itemLink, a, b, c)
		if IsShiftKeyDown() and not IsControlKeyDown() then
			local itemId = select(3, strfind(itemLink, "item:(%d+)"))

			if PQL.focusedEditBox and PQL.focusedEditBox.OnModifiedItemClick then
				PQL.focusedEditBox.OnModifiedItemClick(itemId, itemLink)
			end

			self:Fire("ModifiedItemClick", tonumber(itemId))
		end
    end)

	-- Create a scan tool frame.
	self.scanTool = CreateFrame("GameTooltip", "PQLScanTooltip", nil, "GameTooltipTemplate")
	self.scanTool:SetOwner(WorldFrame, "ANCHOR_NONE")

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
	self.ph:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.ph:SetScript("OnEvent", function(_, event, arg1, arg2)
		-- Store merchant items when a store is opened.
		if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
			PQLUtil.Merchant:Update()

		-- Bag items or currency have changed. Process goals.
		elseif event == "BAG_UPDATE" or event == "CURRENCY_DISPLAY_UPDATE" then
			self.GOALS:ProcessInventoryDependentGoals()

		-- New combat event that possibly progresses a goal.
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			self.GOALS:ProcessCombatDependentGoals()

		-- Item info received (async response).
		elseif event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
			PQLUtil.Items:_RunGetCallbacks(arg1, arg2)
		end
	end)

	self.GOALS:ProcessInventoryDependentGoals()
end

function PQL:RegisterMinimapButton()
    local dataObject = LibDB:NewDataObject("PersonalQuestLog", {
        icon = PQLPath("Art\\Icon.png"),
        text = "Personal Quest Log",
        type = "launcher",
        OnClick = function() self:Toggle() end,
        OnTooltipShow = function(tooltip) tooltip:AddLine("Personal Quest Log") end
    })

    LibIcon:Register("PersonalQuestLog", dataObject, {hide = false})
end

function PQL:RegisterSlashCommands()
    self:RegisterChatCommand("pql", "OnSlashCommand")
    self:RegisterChatCommand("personalquestlog", "OnSlashCommand")
end

function PQL:OnSlashCommand(input)
    if not input then input = "" end

    input = input:trim()

    if input == "" then
        self:Toggle()
    elseif input == "settings" then
        Settings.OpenToCategory("Personal Quest Log")
    else
        self:Print("Available commands:")
        self:Print("/pql settings")
    end
end

function PQL:Toggle()
    self.main:Toggle()
end

function PQL:SetupDebuggingTools()
    self.reloadButton = PQL.FACTORY.Button:CreateButton(UIParent, {
        width = 100,
        text = "Reload",
        anchor = { "TOP", UIParent, "TOP", 0, -10 },
        OnClick = function() ReloadUI() end
    })
end

function PQL:On(event, callback)
    if not self.eventListeners[event] then
        self.eventListeners[event] = {}
    end

    table.insert(self.eventListeners[event], callback)
end

function PQL:Fire(event, data)
    if self.eventListeners[event] then
        for _, callback in ipairs(self.eventListeners[event]) do
            callback(data)
        end
    end
end
