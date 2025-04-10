
local shader = {
    vertPath = "objectUI.vert.spv",
    fragPath = "objectUIRadialMaskOutline.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "disabled",
        cull = "back",
    },
}

return shader