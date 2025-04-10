
local shader = {
    vertPath = "particleRain.vert.spv",
    fragPath = "particleRain.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader