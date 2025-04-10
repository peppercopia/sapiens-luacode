
local shader = {
    vertPath = "objectUI.vert.spv",
    fragPath = "objectUIRadialMask.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader