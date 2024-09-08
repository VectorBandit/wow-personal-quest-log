local nineSliceData = {
    tl = {
        {p = "TOPLEFT"},
        {p = "BOTTOMRIGHT", rp = "TOPLEFT", x = 6, y = -6},
        {0, 0.25, 0, 0.25}
    },
    l = {
        {p = "TOPLEFT", y = -6},
        {p = "BOTTOMRIGHT", rp = "BOTTOMLEFT", x = 6, y = 6},
        {0, 0.25, 0.25, 0.75}
    },
    bl = {
        {p = "TOPLEFT", rp = "BOTTOMLEFT", y = 6},
        {p = "BOTTOMRIGHT", rp = "BOTTOMLEFT", x = 6},
        {0, 0.25, 0.75, 1}
    },
    t = {
        {p = "TOPLEFT", x = 6},
        {p = "BOTTOMRIGHT", rp = "TOPRIGHT", x = -6, y = -6},
        {0.25, 0.75, 0, 0.25}
    },
    m = {
        {p = "TOPLEFT", x = 6, y = -6},
        {p = "BOTTOMRIGHT", x = -6, y = 6},
        {0.25, 0.75, 0.25, 0.75}
    },
    b = {
        {p = "TOPLEFT", rp = "BOTTOMLEFT", x = 6, y = 6},
        {p = "BOTTOMRIGHT", x = -6},
        {0.25, 0.75, 0.75, 1}
    },
    tr = {
        {p = "TOPRIGHT"},
        {p = "BOTTOMLEFT", rp = "TOPRIGHT", x = -6, y = -6},
        {0.75, 1, 0, 0.25}
    },
    r = {
        {p = "TOPRIGHT", y = -6},
        {p = "BOTTOMLEFT", rp = "BOTTOMRIGHT", x = -6, y = 6},
        {0.75, 1, 0.25, 0.75}
    },
    br = {
        {p = "TOPRIGHT", rp = "BOTTOMRIGHT", y = 6},
        {p = "BOTTOMLEFT", rp = "BOTTOMRIGHT", x = -6},
        {0.75, 1, 0.75, 1}
    },
}

function PQLNineSlice(frame, file)
    for slice, sliceData in pairs(nineSliceData) do
        if not frame[slice] then
            frame[slice] = frame:CreateTexture(nil, "BACKGROUND")
        end

        frame[slice]:SetTexture(PQLArt("9Slice-"..file..".png"))
        frame[slice]:SetTexCoord(unpack(sliceData[3]))
        frame[slice]:SetPoint(sliceData[1].p, frame, sliceData[1].rp or sliceData[1].p, sliceData[1].x or 0, sliceData[1].y or 0)
        frame[slice]:SetPoint(sliceData[2].p, frame, sliceData[2].rp or sliceData[2].p, sliceData[2].x or 0, sliceData[2].y or 0)
    end
end
