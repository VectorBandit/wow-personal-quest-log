PQL.confirmationPopup = CreateFrame("Frame", nil, UIParent)
local c = PQL.confirmationPopup

function PQL.confirmationPopup:Init()
    c:SetFrameStrata("DIALOG")

    c:SetSize(250, 91)
    c:SetPoint("CENTER")
    c:Hide()

	PQLNineSlice(c, "Frame")

    c.confirmed = false

	c.title = c:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	PQLSetFont(c.title, {})
	c.title:SetPoint("CENTER", c, "TOP", 0, -24)

    c.cancelButton = PQLFactory.Button:CreateButton(c, {
        text = "Cancel",
        width = 60,
        anchor = {"BOTTOMLEFT", c, "BOTTOMLEFT", 11, 11},
        OnClick = function()
            c.confirmed = false
            c:Close()
        end
    })

    c.confirmButton = PQLFactory.Button:CreateButton(c, {
        text = "Yes",
        width = 60,
        anchor = {"BOTTOMRIGHT", c, "BOTTOMRIGHT", -11, 11},
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

function PQL.confirmationPopup:Open(params)
    c.title:SetText(params.title or "Are you sure?")

    c.cancelButton.text:SetText(params.cancelText or "Cancel")
    c.confirmButton.text:SetText(params.confirmText or "Yes")

    c.cancelCallback = params.OnCancel
    c.confirmCallback = params.OnConfirm

    c:Show()
end

function PQL.confirmationPopup:Close()
	if c.confirmed and c.confirmCallback then
		c.confirmCallback()
	elseif c.cancelCallback then
		c.cancelCallback()
	end

	c:Hide()
end
