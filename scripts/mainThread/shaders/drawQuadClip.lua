
local shader = {
    vertPath = "drawQuadClip.vert.spv",
    fragPath = "drawQuadClip.frag.spv",
    options = {
        blendMode = "premultiplied",
        --depth = "testOnly",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader