
local shader = {
    vertPath = "objectToCubeInstanced.vert.spv",
    fragPath = "object.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader