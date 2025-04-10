
local shader = {
    vertPath = "skyToCube.vert.spv",
    fragPath = "sky.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader