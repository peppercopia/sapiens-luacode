
local shader = {
    vertPath = "drawQuadTexturedClip.vert.spv",
    fragPath = "drawQuadTexturedMaskedClip.frag.spv",
    options = {
        blendMode = "nonPremultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader