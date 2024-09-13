PQL.FACTORY.DynamicList = {}

function PQL.FACTORY.DynamicList:Create(parent, params)
    local List = {
        entries = {},
        items = {}
    }

    List.parent = parent
    List.topAnchor = params.topAnchor or {{"TOPLEFT"}, {"TOPRIGHT"}}
    List.spacing = params.spacing or 10
    List.actions = params.actions or {}

    function List:FetchEntries(fetchParams)
        if self.actions.FetchEntries then
            self.entries = self.actions.FetchEntries(fetchParams)
        else
            PQL:Print("No entry fetching function provided for DynamicList.")
        end
    end

    function List:Create(firstTimeCreateOnlyEntryData, additionalParams)
        if self.actions.Create then
            local result = self.actions.Create(parent, firstTimeCreateOnlyEntryData, additionalParams)
            if result == nil then
                PQL:Print("[ERROR] Factory function for dynamic list did not return a frame.")
            end
            result.data = firstTimeCreateOnlyEntryData
            return result
        end

        PQL:Print("No factory function provided for DynamicList.")
    end

    function List:Init(entryFrame, entryData, initParams)
        entryFrame.data = entryData

        if self.actions.Init then
            self.actions.Init(entryFrame, initParams)
        else
            PQL:Print("No init function provided for DynamicList.")
        end
    end

    function List:UpdateParentHeight()
        local height = self:GetListHeight()

        if params.FilterParentHeight then
            height = params.FilterParentHeight(height)
        end

        self.parent:SetHeight(height)
    end

    function List:Populate(fetchParams, initParams)
        self:FetchEntries(fetchParams)

        local index = 1

        -- Hide every item to reset the list.
        for _, item in pairs(self.items) do
            item:Hide()
            item.active = false
        end

        for _, entry in pairs(self.entries) do
            if not self.items[index] then
                self.items[index] = self:Create(entry, initParams)
            end

            -- Update position.
            self.items[index]:ClearAllPoints()

            if index == 1 then
                PQLSetPoints(self.items[index], self.topAnchor)
            else
                PQLSetPoints(self.items[index], {
                    {"TOPLEFT", self.items[index - 1], "BOTTOMLEFT", 0, -self.spacing},
                    {"RIGHT"}
                })
            end

            -- Update data.
            self:Init(self.items[index], entry, initParams)

            -- Update display.
            self.items[index]:Show()
            self.items[index].active = true

            -- Update index.
            index = index + 1
        end

        -- Set the parent height based on the final height of this list.
        self:UpdateParentHeight()
    end

    function List:GetListHeight()
        local height = 1
        local itemCount = 0

        for _, item in ipairs(self.items) do
            if item and item.active then
                height = height + item:GetHeight()
                itemCount = itemCount + 1
            end
        end

        height = height + (self.spacing * (itemCount - 1))

        return height
    end

	function List:GetItemsCount()
		local count = 0

		for _, item in ipairs(self.items) do
			if item.active then count = count + 1 end
		end

		return count
	end

	function List:IsEmpty()
		return self:GetItemsCount() == 0
	end

    return List
end
