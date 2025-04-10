
local shader = {
    vertPath = "drawQuadTextured.vert.spv",
    fragPath = "drawQuadTexturedMaskedXRay.frag.spv",
    options = {
        blendMode = "nonPremultiplied",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader