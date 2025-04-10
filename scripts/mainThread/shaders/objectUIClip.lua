
local shader = {
    vertPath = "objectUIClip.vert.spv",
    fragPath = "objectUIClip.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader