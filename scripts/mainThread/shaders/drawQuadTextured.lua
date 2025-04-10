
local shader = {
    vertPath = "drawQuadTextured.vert.spv",
    fragPath = "drawQuadTextured.frag.spv",
    options = {
        blendMode = "premultiplied",
        --depth = "testOnly",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader