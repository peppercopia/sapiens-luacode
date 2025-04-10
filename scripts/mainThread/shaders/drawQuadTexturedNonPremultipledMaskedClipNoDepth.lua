
local shader = {
    vertPath = "drawQuadTexturedClip.vert.spv",
    fragPath = "drawQuadTexturedMaskedClip.frag.spv",
    options = {
        blendMode = "nonPremultiplied",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader