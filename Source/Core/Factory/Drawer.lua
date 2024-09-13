PQL.FACTORY.Drawer = {}

function PQL.FACTORY.Drawer:Create(name, params)
	local d = CreateFrame("Frame", name, PQL.main)

	function d:FactoryInit()
		d:SetWidth(500)

		PQLNineSlice(d, "Frame")
		PQLSetPoints(d, {
			{"TOPLEFT", PQL.main, "TOPRIGHT", 5, 0},
			{"BOTTOMLEFT", PQL.main, "BOTTOMRIGHT"}
		})

		-- Tongue Button
		d.tongueButton = PQL.FACTORY.Button:CreateIconButton(d, {
			OnClick = function() d:Close() end,
			icon = "ChevronLeft",
			anchor = { "LEFT", d, "RIGHT", 0, 0 },
			size = 32
		})

		-- Drawer Title
		d.title = d:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PQLSetFont(d.title, { size = 18, text = params.title })
		d.title:SetPoint("LEFT", self, "TOPLEFT", 20, -32)

		-- Scroll Frame
		PQL.FACTORY.ScrollFrame:Create(d, {
			width = 500,
			inset = 20,
			yOffset = -44,
		})

		-- Run custom initialize function
		d:Init()

		-- Allow the player to close the drawer when pressing Escape.
		tinsert(UISpecialFrames, d:GetName())
	end

	function d:Open(data)
		PQL.main:CloseDrawers()

		d.isOpen = true
		d:Show()

		if d.OnOpen then
			d:OnOpen(data)
		end
	end

	function d:Close()
		if not d.isOpen then return end

		d.isOpen = false
		d:Hide()

		if d.OnClose then
			d:OnClose()
		end
	end

	return d
end
