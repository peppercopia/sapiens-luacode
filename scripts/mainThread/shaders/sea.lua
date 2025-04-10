
local shader = {
    vertPath = "sea.vert.spv",
    fragPath = "sea.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "back",
    },
}

return shader