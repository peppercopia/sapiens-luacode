
local shader = {
    vertPath = "drawQuadTextured.vert.spv",
    fragPath = "drawQuadTexturedMasked.frag.spv",
    options = {
        blendMode = "nonPremultiplied",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader