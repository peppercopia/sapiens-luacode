
local shader = {
    vertPath = "drawQuadTexturedClip.vert.spv",
    fragPath = "drawQuadTexturedClip.frag.spv",
    options = {
        blendMode = "premultiplied",
        --depth = "testOnly",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader