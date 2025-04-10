
local shader = {
    vertPath = "particle.vert.spv",
    fragPath = "particle.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader