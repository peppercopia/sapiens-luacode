
local shader = {
    vertPath = "objectBoned.vert.spv",
    fragPath = "object.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testAndMask",
        cull = "front",
    },
}
return shader