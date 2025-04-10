
local shader = {
    vertPath = "texturedVertColored.vert.spv",
    fragPath = "texturedVertColored.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader