PQLTable = {}

PQLTable.length = function(t)
    local c = 0
    for _, i in ipairs(t) do
        if i ~= nil then
            c = c + 1
        end
    end
    return c
end

PQLTable.clean = function(t)
    local r = {}
    for _, i in ipairs(t) do
        if i ~= nil then
            table.insert(r, i)
        end
    end
    return r
end

PQLTable.fromKeyValue = function(t, key, value, multiple)
	local result = {}

	for _, i in ipairs(t) do
		if type(i) == "table" and i[key] == value then
			if multiple then
				table.insert(result, i)
			else
				return i
			end
		end
	end

	return multiple and result or nil
end

PQLString = {}

PQLString.insert = function(str1, str2, pos)
	return str1:sub(1, pos)..str2..str1:sub(pos + 1)
end

