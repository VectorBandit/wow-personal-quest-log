PQL.dropdown = CreateFrame("Frame", "PQLDropdown", UIParent)
local d = PQL.dropdown

function PQL.dropdown:Init()
	d:SetAllPoints(UIParent)

	d.backdrop = CreateFrame("Frame", "PQLDropdownBackdrop", d)
	d.backdrop:SetFrameStrata("FULLSCREEN")
	d.backdrop:SetAllPoints(UIParent)
	d.backdrop:HookScript("OnMouseUp", function() self:Close() end)

	d.popup = CreateFrame("Frame", "PQLDropdownPopup", d)
	d.popup:SetFrameStrata("FULLSCREEN_DIALOG")
	d.popup:SetSize(96, 100)
	PQLNineSlice(d.popup, "Frame_Filled")

	d.popup.list = {}
	d.popup.toolbar = {}

	tinsert(UISpecialFrames, d.backdrop:GetName())
	tinsert(UISpecialFrames, d.popup:GetName())
end

function PQL.dropdown:Close()
	d.popup:Hide()
	d.backdrop:Hide()
end

function PQL.dropdown:Open(list, toolbar)
	if not toolbar then toolbar = {} end
	if not list then list = {} end

	local hasToolbar = PQLTable.length(toolbar) > 0
	local hasList = PQLTable.length(list) > 0

	-- Bail early if no options were provided.
	if not hasToolbar and not hasList then return end

	d.popup:Show()
	d.backdrop:Show()

	-- Set Position
	local scale = self:GetEffectiveScale()
	local x, y = GetCursorPosition()
	d.popup:ClearAllPoints()
	d.popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)

	-- Set Height
	local height = (PQLTable.length(list) * 24) + (hasToolbar and 24 or 0)
	d.popup:SetHeight(height)

	-- Prepare Width (Will be applied at the end)
	local width = 96
	if hasToolbar then width = PQLTable.length(toolbar) * 24 end

	-- Setup Toolbar
	for _, item in ipairs(d.popup.toolbar) do
		item:Hide()
	end

	if hasToolbar then
		for i, item in ipairs(toolbar) do
			item.anchor = {"TOPRIGHT", d.popup, "TOPRIGHT", -(24 * (i - 1)), 0}

			local cb = item.callback
			item.callback = function()
				d:Close()
				cb()
			end

			if not d.popup.toolbar[i] then
				d.popup.toolbar[i] = PQLFactory.Button:CreateIconButton(d.popup, item)
			else
				d.popup.toolbar[i]:Update(item)
			end

			d.popup.toolbar[i]:Show()
		end
	end

	-- Setup List
	for _, item in ipairs(d.popup.list) do
		item:Hide()
	end

	if hasList then
		for i, item in ipairs(list) do
			item.anchor = {
				{"TOPLEFT", d.popup, "TOPLEFT", 0, -(24 * (hasToolbar and i or i - 1))},
				{"RIGHT", d.popup}
			}

			local cb = item.callback
			item.callback = function()
				d:Close()
				cb()
			end

			item.justify = "LEFT"
			item.style = "text-default"

			if not d.popup.list[i] then
				d.popup.list[i] = PQLFactory.Button:CreateButton(d.popup, item)
			else
				d.popup.list[i]:Update(item)
			end

			d.popup.list[i]:Show()

			local itemWidth = d.popup.list[i].text:GetStringWidth() + 12 -- Add horizontal padding

			if itemWidth > width then
				width = itemWidth
			end
		end
	end

	-- Clamp the width
	if width > 250 then
		width = 250
	end

	d.popup:SetWidth(width)
end

