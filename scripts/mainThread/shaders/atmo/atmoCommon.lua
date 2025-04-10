
local atmoCommon = {
    uniforms = {
        {
            type = "UNIFORM_BUFFER",
            stage = "VERT"
        },
        {
            type = "UNIFORM_BUFFER",
            stage = "FRAG"
        },
    },
    attributes = {
        {
            name = "position",
            components = 2
        },
    },
    vertPaths = {
        "atmo/atmo.vert"
    },
    fragPaths = {
        
    },
    options = {
        blendMode = "treatAlphaAsColorChannel"
    }
}

function atmoCommon:combine(otherShader)
    local combined = {
        uniforms = mj:concatTables(atmoCommon.uniforms, otherShader.uniforms),
        attributes = mj:concatTables(atmoCommon.attributes, otherShader.attributes),
        vertPaths = mj:concatTables(atmoCommon.vertPaths, otherShader.vertPaths),
        fragPaths = mj:concatTables(atmoCommon.fragPaths, otherShader.fragPaths),
    }
    return combined
end

return atmoCommon