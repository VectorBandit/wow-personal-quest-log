PQLFactory.ScrollFrame = {}

function PQLFactory.ScrollFrame:Create(parent, params)
	parent.scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	local s = parent.scrollFrame

	if not params.inset then
		params.inset = 10
	end

	PQLSetPoints(s, {{"TOPLEFT", 0, (params.yOffset or 0) - params.inset}, {"BOTTOMRIGHT"}})

	-- Style
	s.ScrollBar:ClearAllPoints()
	s.ScrollBar:SetPoint("TOPLEFT", s, "TOPRIGHT", -24 - params.inset, -24)
	s.ScrollBar:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -params.inset, 24 + params.inset)

	PQLNineSlice(s.ScrollBar, "ScrollBackdrop")

	s.ScrollBar.ThumbTexture:SetSize(24, 24)
	s.ScrollBar.ThumbTexture:SetTexture(PQLArt("ScrollThumb.png"))
	s.ScrollBar.ThumbTexture:SetTexCoord(0, 1, 0, 1)

	s.ScrollBar.ScrollUpButton:SetSize(24, 24)

	s.ScrollBar.ScrollUpButton.Normal:SetTexture(PQLArt("ScrollUp.png"))
	s.ScrollBar.ScrollUpButton.Normal:SetTexCoord(0, 0.25, 0, 1)
	s.ScrollBar.ScrollUpButton.Highlight:SetTexture(PQLArt("ScrollUp.png"))
	s.ScrollBar.ScrollUpButton.Highlight:SetTexCoord(0.25, 0.5, 0, 1)
	s.ScrollBar.ScrollUpButton.Pushed:SetTexture(PQLArt("ScrollUp.png"))
	s.ScrollBar.ScrollUpButton.Pushed:SetTexCoord(0.5, 0.75, 0, 1)
	s.ScrollBar.ScrollUpButton.Disabled:SetTexture(PQLArt("ScrollUp.png"))
	s.ScrollBar.ScrollUpButton.Disabled:SetTexCoord(0.75, 1, 0, 1)

	s.ScrollBar.ScrollDownButton:SetSize(24, 24)

	s.ScrollBar.ScrollDownButton.Normal:SetTexture(PQLArt("ScrollDown.png"))
	s.ScrollBar.ScrollDownButton.Normal:SetTexCoord(0, 0.25, 0, 1)
	s.ScrollBar.ScrollDownButton.Highlight:SetTexture(PQLArt("ScrollDown.png"))
	s.ScrollBar.ScrollDownButton.Highlight:SetTexCoord(0.25, 0.5, 0, 1)
	s.ScrollBar.ScrollDownButton.Pushed:SetTexture(PQLArt("ScrollDown.png"))
	s.ScrollBar.ScrollDownButton.Pushed:SetTexCoord(0.5, 0.75, 0, 1)
	s.ScrollBar.ScrollDownButton.Disabled:SetTexture(PQLArt("ScrollDown.png"))
	s.ScrollBar.ScrollDownButton.Disabled:SetTexCoord(0.75, 1, 0, 1)

	-- Child
	parent.scrollChild = CreateFrame("Frame", nil, parent)
	s:SetScrollChild(parent.scrollChild)
	parent.scrollChild:SetWidth(params.width - 24 - params.inset)
	parent.scrollChild:SetHeight(1)

	parent.inner = CreateFrame("Frame", nil, parent.scrollChild)
	PQLPrepareForText(parent.inner)

	PQLSetPoints(parent.inner, {
		{"TOPLEFT", parent.scrollChild, params.inset, 0},
		{"RIGHT", parent.scrollChild, -params.inset, 0}
	})

	-- Space at the end
	parent.inner.bottomGutter = CreateFrame("Frame", nil, parent.inner)
	parent.inner.bottomGutter:SetPoint("TOPLEFT", parent.inner, "BOTTOMLEFT")
	parent.inner.bottomGutter:SetSize(50, 50)

	return parent.inner
end
