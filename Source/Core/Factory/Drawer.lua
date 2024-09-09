PQLFactory.Drawer = {}

function PQLFactory.Drawer:Create(name, params)
	local d = CreateFrame("Frame", name, PQL.main)

	function d:FactoryInit()
		d:SetWidth(500)

		PQLNineSlice(d, "Dialog")
		PQLSetPoints(d, {
			{"TOPLEFT", PQL.main, "TOPRIGHT"},
			{"BOTTOMLEFT", PQL.main, "BOTTOMRIGHT"}
		})

		-- Tongue Button
		d.tongueButton = PQLFactory.Button:CreateIconButton(d, {
			callback = function() d:Close() end,
			icon = "Special-DrawerTongue",
			anchor = { "LEFT", d, "RIGHT", 0, 0 },
			size = 32
		})

		-- Scroll Frame
		PQLFactory.ScrollFrame:Create(d, {
			width = 500,
			inset = 24
		})

		-- Drawer Title
		d.inner.title = d.inner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		d.inner.title:SetPoint("TOPLEFT")

		PQLSetFont(d.inner.title, {
			size = 18,
			text = params.title
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
		d.isOpen = false
		d:Hide()

		if d.OnClose then
			d:OnClose()
		end
	end

	return d
end
