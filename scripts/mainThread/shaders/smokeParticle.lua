
local shader = {
    vertPath = "smokeParticle.vert.spv",
    fragPath = "particle.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
        --alphaToCoverage = true,
    },
}

return shader