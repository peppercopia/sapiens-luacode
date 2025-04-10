
local shader = {
    vertPath = "particleWeather.vert.spv",
    fragPath = "particleWeather.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader