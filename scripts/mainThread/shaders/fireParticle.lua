
local shader = {
    vertPath = "fireParticle.vert.spv",
    fragPath = "fireParticle.frag.spv",
    options = {
        blendMode = "additive",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader