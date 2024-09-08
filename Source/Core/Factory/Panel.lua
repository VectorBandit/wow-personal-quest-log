PQLFactory.Panel = {}

function PQLFactory.Panel:Create(name, params)
    local panel = CreateFrame("Frame", "PQL_"..name, UIParent)
	panel.modules = {}
	panel.drawers = {}

    function panel:AddModule(module)
        if not tContains(panel.modules, module) then
            tinsert(panel.modules, module)
        end
    end

    function panel:AddDrawer(drawer)
        if not tContains(panel.drawers, drawer) then
            tinsert(panel.drawers, drawer)
        end
    end

    function panel:FactoryInit()
		PQLNineSlice(panel, "Dialog")

		panel:SetFrameStrata("HIGH")
		panel:SetMovable(true)
		panel:SetClampedToScreen(true)
		panel:SetToplevel(true)
		panel:SetFlattensRenderLayers(true)

		-- Add inner area
		PQLFactory.ScrollFrame:Create(panel, {
			yOffset = -45,
			width = params.size[1]
		})

		-- Run custom initialize function
        panel:Init()

		-- Set center point
		panel:SetPoint("CENTER")

		-- Set size
		if params.size then
			panel:SetSize(unpack(params.size))
		end

		-- Allow dragging
		PQL.main:SetScript("OnMouseDown", function(self, button, ...)
			PQL.main:StartMoving()
			PQL.main.isMoving = true
		end)

		PQL.main:SetScript("OnMouseUp", function(self, button, ...)
			PQL.main:StopMovingOrSizing()
			PQL.main.isMoving = false
		end)

		-- Initialize modules.
        for _, module in ipairs(panel.modules) do
            if panel[module]["FactoryInit"] then
                panel[module]:FactoryInit()
            end
        end
    end

    function panel:Toggle()
        if panel:IsVisible() then
            panel:Hide()
        else
            panel:Show()
        end
    end

    function panel:CloseDrawers()
        for _, drawer in ipairs(panel.drawers) do
            if panel[drawer]["Close"] then
                panel[drawer]:Close()
            end
        end
    end

    panel:SetScript("OnShow", function()
		panel.isOpen = true

        if panel["OnShow"] then
            panel:OnShow()
        end

        for _, module in ipairs(panel.modules) do
            if panel[module]["OnPanelShow"] then
                panel[module]:OnPanelShow()
            end
        end
    end)

    panel:SetScript("OnHide", function()
		panel.isOpen = false

        if panel["OnHide"] then
            panel:OnHide()
        end

        for _, module in ipairs(panel.modules) do
            if panel[module]["OnPanelHide"] then
                panel[module]:OnPanelHide()
            end
        end
    end)

    return panel
end
