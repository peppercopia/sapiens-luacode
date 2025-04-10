
local shader = {
    vertPath = "texturedVertColored.vert.spv",
    fragPath = "texturedVertColoredXRay.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader