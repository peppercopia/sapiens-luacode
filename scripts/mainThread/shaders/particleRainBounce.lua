
local shader = {
    vertPath = "particleRainBounce.vert.spv",
    fragPath = "particleRainBounce.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader