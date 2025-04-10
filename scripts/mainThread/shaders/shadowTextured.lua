
local shader = {
    uniforms = {
        "mvMatrix",
        "pMatrix",
        "texMap",
    },
    attributes = {
        {
            name = "pos",
            components = 3
        },
        {
            name = "tex",
            components = 2
        },
    },
    vertPaths = {
        "shaders/shadowTextured.vsh"
    },
    fragPaths = {
        "shaders/shadowTextured.fsh"
    }
}

return shader