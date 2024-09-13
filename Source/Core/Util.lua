PQL.UTIL = {}

-------------------------------------------------------------------------------
-- » Hyperlinks
-------------------------------------------------------------------------------

PQL.UTIL.LINK = {}

function PQL.UTIL.LINK:GetType(link)
	if strfind(link, "item:(%d+)") then
		return "item"
	elseif strfind(link, "currency:(%d+)") then
		return "currency"
	elseif strfind(link, "worldmap:(%d+):(%d+):(%d+)") then
		return "map"
	end
end

-- @see https://wowpedia.fandom.com/wiki/Hyperlinks#item
function PQL.UTIL.LINK:GetItemId(link)
	return select(3, strfind(link, "item:(%d+)"))
end

-- @see https://wowpedia.fandom.com/wiki/Hyperlinks#currency
function PQL.UTIL.LINK:GetCurrencyId(link)
	return select(3, strfind(link, "currency:(%d+)"))
end

function PQL.UTIL.LINK:GetMapPointInfo(link)
	local _, _, mapId, x, y = strfind(link, "worldmap:(%d+):(%d+):(%d+)")

	if mapId and x and y then
		mapId = tonumber(mapId)
		x = tonumber(x)
		y = tonumber(y)

		local mapPoint = UiMapPoint.CreateFromVector2D(mapId, {
			x = x / 10000,
			y = y / 10000
		})

		return unpack({
			{mapId = mapId, x = x, y = y},
			mapPoint
		})
	end

	return nil
end

-- @see https://wowpedia.fandom.com/wiki/Hyperlinks#worldmap
function PQL.UTIL.LINK:MakePin(uiMapId, x, y)
	local mapId = C_Map.GetBestMapForUnit("player")
	local mapInfo = C_Map.GetMapInfo(mapId)
	local x, y = C_Map.GetPlayerMapPosition(mapId, "player"):GetXY()

	return string.format("|cffffff00|Hworldmap:%d:%d:%d|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a %s]|h|r", mapId, x * 10000, y * 10000, mapInfo.name)
end

function PQL.UTIL.LINK:MakeUnit(npcId)
	local npcName = PQL.UTIL.UNIT:GetNameFromID(npcId)
	if not npcName then npcName = npcId end

	return string.format("|Hunit:Creature-0-0-0-0-%d:%s|h[%s]|h", npcId, npcName, npcName)
end

-------------------------------------------------------------------------------
-- » Units
-------------------------------------------------------------------------------

PQL.UTIL.UNIT = {}

function PQL.UTIL.UNIT:ShowTooltip(id, anchorTo)
	if anchorTo then PQLAnchorTooltip(anchorTo) end
	if not id then id = 0 end
	id = tonumber(id) or 0

	GameTooltip:SetHyperlink(string.format("unit:Creature-0-0-0-0-%d", id))
	GameTooltip:Show()
end

function PQL.UTIL.UNIT:GetIDFromGUID(unitGUID)
	local unitID = select(6, strsplit("-", unitGUID))
	return unitID and tonumber(unitID) or nil
end

function PQL.UTIL.UNIT:GetNameFromID(npcId)
	if not npcId then return nil end
	npcId = tonumber(npcId)
	if not npcId then return nil end

	local tooltipInfo = C_TooltipInfo.GetHyperlink(string.format("unit:Creature-0-0-0-0-%d", npcId))
	if not tooltipInfo or type(tooltipInfo) ~= "table" then return nil end -- Probably still querying.

	return tooltipInfo.lines[1].leftText
end

function PQL.UTIL.UNIT:GetTypeFromGUID(unitGUID)
	return strsplit("-", unitGUID)
end

function PQL.UTIL.UNIT:IsInParty(unitGUID)
	-- Player or Player's Pet
	if UnitGUID("player") == unitGUID or UnitGUID("pet") == unitGUID then
		return true
	end

	-- Party Member or Party Member's Pet
	for i = 1, 4 do
		if UnitGUID("party"..i) == unitGUID or UnitGUID("partypet"..i) == unitGUID then
			return true
		end
	end

	-- Raid Member or Raid Member's Pet
	for i = 1, 40 do
		if UnitGUID("raid"..i) == unitGUID or UnitGUID("raidpet"..i) == unitGUID then
			return true
		end
	end

	return false
end

-------------------------------------------------------------------------------
-- » Items
-------------------------------------------------------------------------------

PQL.UTIL.ITEM = {
	_getCallbacks = {}
}

function PQL.UTIL.ITEM:ShowTooltip(id, anchorTo)
	self:Get(id, function(item)
		if item then
			if anchorTo then PQLAnchorTooltip(anchorTo) end
			GameTooltip:SetHyperlink(item.link)
			GameTooltip:Show()
		end
	end)
end

function PQL.UTIL.ITEM:Get(id, callback)
	if not id or id == "" then return callback(nil) end

	local itemName, itemLink = C_Item.GetItemInfo(id)

	if not itemName then
		-- WoW is probably still processing the request.
		-- Let's save the callback and maybe respond later.
		if not PQL.UTIL.ITEM._getCallbacks["item_"..id] then
			PQL.UTIL.ITEM._getCallbacks["item_"..id] = {}
		end

		table.insert(PQL.UTIL.ITEM._getCallbacks["item_"..id], callback)

		-- Immediately respond with nil.
		callback(nil)
	else
		callback({
			id = id,
			name = itemName,
			link = itemLink,
		})
	end
end

function PQL.UTIL.ITEM:GetCount(id)
	id = tonumber(id)
	if not id then return 0 end

	return GetItemCount(id, true, false, true)
end

function PQL.UTIL.ITEM:_RunGetCallbacks(id, success)
	if not PQL.UTIL.ITEM._getCallbacks["item_"..id] then return end

	for i, callback in ipairs(PQL.UTIL.ITEM._getCallbacks["item_"..id]) do
		if callback and success then
			-- Call the Get function again, which will hopefully return the item correctly this time.
			PQL.UTIL.ITEM:Get(id, callback)
			PQL.UTIL.ITEM._getCallbacks["item_"..id][i] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- » Currencies
-------------------------------------------------------------------------------

PQL.UTIL.CURRENCY = {}

function PQL.UTIL.CURRENCY:ShowTooltip(id, anchorTo)
	local currency = self:Get(id)

	if currency then
		if anchorTo then PQLAnchorTooltip(anchorTo) end
		GameTooltip:SetHyperlink(currency.link)
		GameTooltip:Show()
	end
end

function PQL.UTIL.CURRENCY:Get(id)
	id = tonumber(id)
	if not id then return nil end

	local currency = C_CurrencyInfo.GetCurrencyInfo(id)
	if not currency then return nil end

	return {
		id = id,
		name = currency.name,
		link = C_CurrencyInfo.GetCurrencyLink(id)
	}
end

function PQL.UTIL.CURRENCY:GetCount(id)
	id = tonumber(id)
	if not id then return 0 end

	local currency = self:Get(id)
	if not currency then return 0 end
	return C_CurrencyInfo.GetCurrencyInfo(currency.id).quantity or 0
end

-------------------------------------------------------------------------------
-- » Merchants
-------------------------------------------------------------------------------

PQL.UTIL.MERCHANT = {
	_items = {}
}

function PQL.UTIL.MERCHANT:Update()
	self._items = {}

	local numItems = GetMerchantNumItems()

	for i = 1, numItems do
		self._items[i] = GetMerchantItemID(i)
	end
end

function PQL.UTIL.MERCHANT:GetItemCost(index)
	local cost = {}
	local numResources = GetMerchantItemCostInfo(index)

	for i = 1, numResources do
		local _, amount, link, currencyName = GetMerchantItemCostItem(index, i)

		cost[i] = {
			amount = amount,
			type = currencyName and PQL_GOALTYPE_CURRENCY or PQL_GOALTYPE_ITEM,
			id = currencyName and
				PQL.UTIL.LINK:GetCurrencyId(link) or
				PQL.UTIL.LINK:GetItemId(link)
		}
	end

	return cost
end

function PQL.UTIL.MERCHANT:GetItem(index)
	local id = self._items[index]
	local name, link = C_Item.GetItemInfo(id)

	if not name then return nil end

	return {
		id = id,
		name = name,
		link = link,
		cost = self:GetItemCost(index)
	}
end

function PQL.UTIL.MERCHANT:GetItemByID(itemId)
	for index, id in pairs(self._items) do
		if id == itemId then return self:GetItem(index) end
	end

	return nil
end

