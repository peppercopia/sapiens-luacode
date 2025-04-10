
local shader = {
    vertPath = "waterRipples.vert.spv",
    fragPath = "waterRipples.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
        --alphaToCoverage = true,
    },
}

return shader