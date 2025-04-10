
local shader = {
    vertPath = "stars.vert.spv",
    fragPath = "starsConstExposure.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
        topology = "points",
    },
}

return shader