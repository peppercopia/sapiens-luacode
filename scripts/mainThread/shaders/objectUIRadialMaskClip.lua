
local shader = {
    vertPath = "objectUIClip.vert.spv",
    fragPath = "objectUIRadialMaskClip.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader