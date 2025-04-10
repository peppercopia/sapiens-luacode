
local shader = {
    vertPath = "spark.vert.spv",
    fragPath = "spark.frag.spv",
    options = {
        blendMode = "additive",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader