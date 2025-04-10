
local shader = {
    vertPath = "drawQuad.vert.spv",
    fragPath = "drawQuad.frag.spv",
    options = {
        blendMode = "premultiplied",
        --depth = "testOnly",
        depth = "disabled",
        cull = "disabled",
    },
}

return shader