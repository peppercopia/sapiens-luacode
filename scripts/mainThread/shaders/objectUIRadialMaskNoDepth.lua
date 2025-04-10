
local shader = {
    vertPath = "objectUI.vert.spv",
    fragPath = "objectUIRadialMask.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "disabled",
        cull = "back",
    },
}

return shader