
local shader = {
    vertPath = "cloud.vert.spv",
    fragPath = "cloudBlended.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader