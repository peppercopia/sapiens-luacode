
local shader = {
    vertPath = "drawQuadTextured.vert.spv",
    fragPath = "drawQuadTexturedMasked.frag.spv",
    options = {
        blendMode = "nonPremultiplied",
        --depth = "disabled",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader