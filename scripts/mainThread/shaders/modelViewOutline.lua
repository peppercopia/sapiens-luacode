
local shader = {
    vertPath = "objectUI.vert.spv",
    fragPath = "modelViewOutline.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "disabled",
        cull = "back",
    },
}

return shader