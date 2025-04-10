
local shader = {
    vertPath = "objectBoned.vert.spv",
    fragPath = "object.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "disabled",
    },
}
return shader