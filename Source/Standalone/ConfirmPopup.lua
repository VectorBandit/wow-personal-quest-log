PQL.confirmPopup = CreateFrame("Frame", nil, UIParent)
local c = PQL.confirmPopup

function PQL.confirmPopup:Init()
    c:SetFrameStrata("DIALOG")

    c:SetSize(250, 91)
    c:SetPoint("CENTER")
    c:Hide()

	PQLNineSlice(c, "Frame")

    c.confirmed = false

	c.title = c:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PQLSetFont(c.title, {size = 16})
	PQLSetPoints(c.title, {{"TOPLEFT", c, 20, -20}, {"TOPRIGHT", -20, -20}})

	c.text = c:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PQLSetFont(c.text, {size = 12})
	PQLSetPoints(c.text, {
		{"TOPLEFT", c.title, "BOTTOMLEFT", 0, -20},
		{"TOPRIGHT", c.title, 0, 0}
	})

    c.cancelButton = PQL.FACTORY.Button:CreateButton(c, {
        text = "Cancel",
        width = 60,
        anchor = {"TOPLEFT", c.text, "BOTTOMLEFT", 0, -20},
        OnClick = function()
            c.confirmed = false
            c:Close()
        end
    })

    c.confirmButton = PQL.FACTORY.Button:CreateButton(c, {
        text = "Yes",
        width = 60,
        anchor = {"TOPRIGHT", c.text, "BOTTOMRIGHT", 0, -20},
        OnClick = function()
            c.confirmed = true
            c:Close()
        end
    })

    c:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            c.confirmed = false
            c:Close()
        elseif key == "ENTER" then
            c.confirmed = true
            c:Close()
        else
            c:SetPropagateKeyboardInput(true)
        end
    end)
end

function PQL.confirmPopup:Open(params)
    c.title:SetText(params.title or "Are you sure?")
	c.text:SetText(params.text or "")

	if params.text then
		c.cancelButton:SetPoint("TOPLEFT", c.text, "BOTTOMLEFT", 0, -20)
		c.confirmButton:SetPoint("TOPRIGHT", c.text, "BOTTOMRIGHT", 0, -20)
	else
		c.cancelButton:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -20)
		c.confirmButton:SetPoint("TOPRIGHT", c.title, "BOTTOMRIGHT", 0, -20)
	end

    c.cancelButton.text:SetText(params.cancelText or "Cancel")
    c.confirmButton.text:SetText(params.confirmText or "Yes")

    c.cancelCallback = params.OnCancel
    c.confirmCallback = params.OnConfirm

	c:SetHeight(100 + (params.text and (c.text:GetStringHeight() + 20) or 0))
    c:Show()
end

function PQL.confirmPopup:Close()
	if c.confirmed and c.confirmCallback then
		c.confirmCallback()
	elseif c.cancelCallback then
		c.cancelCallback()
	end

	c:Hide()
end
