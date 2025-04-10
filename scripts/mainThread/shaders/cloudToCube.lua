
local shader = {
    vertPath = "cloudToCube.vert.spv",
    fragPath = "cloud.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader