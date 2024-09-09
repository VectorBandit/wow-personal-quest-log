PQL_Data = {}

-------------------------------------------------------------------------------
-- Hyperlinks
-------------------------------------------------------------------------------

PQL_Data.Links = {}

function PQL_Data.Links:GetType(link)
	if strfind(link, "item:(%d+)") then
		return "item"
	elseif strfind(link, "currency:(%d+)") then
		return "currency"
	elseif strfind(link, "worldmap:(%d+):(%d+):(%d+)") then
		return "map"
	end
end

-- @see https://wowpedia.fandom.com/wiki/Hyperlinks#item
function PQL_Data.Links:GetItemId(link)
	return select(3, strfind(link, "item:(%d+)"))
end

-- @see https://wowpedia.fandom.com/wiki/Hyperlinks#currency
function PQL_Data.Links:GetCurrencyId(link)
	return select(3, strfind(link, "currency:(%d+)"))
end

function PQL_Data.Links:GetMapPointInfo(link)
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
function PQL_Data.Links:MakePin(uiMapId, x, y)
	local mapId = C_Map.GetBestMapForUnit("player")
	local mapInfo = C_Map.GetMapInfo(mapId)
	local x, y = C_Map.GetPlayerMapPosition(mapId, "player"):GetXY()

	return string.format("|cffffff00|Hworldmap:%d:%d:%d|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a %s]|h|r", mapId, x * 10000, y * 10000, mapInfo.name)
end

-------------------------------------------------------------------------------
-- Items
-------------------------------------------------------------------------------

PQL_Data.Items = {
	_getCallbacks = {}
}

function PQL_Data.Items:ShowTooltip(id, anchorTo)
	self:Get(id, function(item)
		if item then
			if anchorTo then PQLAttachTooltip(anchorTo) end
			GameTooltip:SetHyperlink(item.link)
			GameTooltip:Show()
		end
	end)
end

function PQL_Data.Items:Get(id, callback)
	if not id then callback(nil) end

	local itemName, itemLink = C_Item.GetItemInfo(id)

	if not itemName then
		-- WoW is probably still processing the request.
		-- Let's save the callback and maybe respond later.
		if not PQL_Data.Items._getCallbacks["item_"..id] then
			PQL_Data.Items._getCallbacks["item_"..id] = {}
		end

		table.insert(PQL_Data.Items._getCallbacks["item_"..id], callback)

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

function PQL_Data.Items:GetCount(id)
	id = tonumber(id)
	if not id then return 0 end

	return GetItemCount(id, true, false, true)
end

function PQL_Data.Items:_RunGetCallbacks(id, success)
	if not PQL_Data.Items._getCallbacks["item_"..id] then return end

	for i, callback in ipairs(PQL_Data.Items._getCallbacks["item_"..id]) do
		if callback and success then
			-- Call the Get function again, which will hopefully return the item correctly this time.
			PQL_Data.Items:Get(id, callback)
			PQL_Data.Items._getCallbacks["item_"..id][i] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Currencies
-------------------------------------------------------------------------------

PQL_Data.Currencies = {}

function PQL_Data.Currencies:ShowTooltip(id, anchorTo)
	local currency = self:Get(id)

	if currency then
		if anchorTo then PQLAttachTooltip(anchorTo) end
		GameTooltip:SetHyperlink(currency.link)
		GameTooltip:Show()
	end
end

function PQL_Data.Currencies:Get(id)
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

function PQL_Data.Currencies:GetCount(id)
	id = tonumber(id)
	if not id then return 0 end

	local currency = self:Get(id)
	if not currency then return 0 end
	return C_CurrencyInfo.GetCurrencyInfo(currency.id).quantity or 0
end

-------------------------------------------------------------------------------
-- Merchants
-------------------------------------------------------------------------------

PQL_Data.Merchant = {
	_items = {}
}

function PQL_Data.Merchant:Update()
	self._items = {}

	local numItems = GetMerchantNumItems()

	for i = 1, numItems do
		self._items[i] = GetMerchantItemID(i)
	end
end

function PQL_Data.Merchant:GetItemCost(index)
	local cost = {}
	local numResources = GetMerchantItemCostInfo(index)

	for i = 1, numResources do
		local _, amount, link, currencyName = GetMerchantItemCostItem(index, i)

		cost[i] = {
			amount = amount,
			type = currencyName and 3 or 2,
			id = currencyName and
				PQL_Data.Links:GetCurrencyId(link) or
				PQL_Data.Links:GetItemId(link)
		}
	end

	return cost
end

function PQL_Data.Merchant:GetItem(index)
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

function PQL_Data.Merchant:GetItemById(itemId)
	for index, id in pairs(self._items) do
		if id == itemId then return self:GetItem(index) end
	end

	return nil
end

