local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("tropicalfish", 1)
animationInfo.default = "slowSwim"

local keyframes = mj:enum {
    "idle",
    "lookLeft", 
    "lookRight",
}

animationInfo.animations = mj:indexed {
    slowSwim = {
        keyframes = {
            { keyframes.lookLeft, 0.4, {randomVariance = 0.1} },
            { keyframes.lookRight, 0.4, {randomVariance = 0.1} },
        },
    },
    fastSwim = {
        keyframes = {
            { keyframes.lookLeft, 0.2, {randomVariance = 0.05} },
            { keyframes.lookRight, 0.2, {randomVariance = 0.05} },
        },
    },
}

function animationInfo:initMainThread()
    
end

return animationInfo