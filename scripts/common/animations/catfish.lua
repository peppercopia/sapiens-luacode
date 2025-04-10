local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("catfish", 1)
animationInfo.default = "slowSwim"

local keyframes = mj:enum {
    "idle",
    "lookLeft", 
    "lookRight",
}

animationInfo.animations = mj:indexed {
    slowSwim = {
        keyframes = {
            { keyframes.lookLeft, 2.5 },
            { keyframes.lookRight, 2.5 },
        },
    },
    fastSwim = {
        keyframes = {
            { keyframes.lookLeft, 1.5 },
            { keyframes.lookRight, 1.5 },
        },
    },
}
function animationInfo:initMainThread()
    
end

return animationInfo

