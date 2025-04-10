local shader = {
    vertPath = "prefilterEnvMapNoMulti.vert.spv",
    fragPath = "prefilterEnvMap.frag.spv",
    options = {
        blendMode = "premultiplied",
        pushConstantsFragSize = mj:sizeof("vec4"),
    }
}

return shader