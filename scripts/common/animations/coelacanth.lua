local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("coelacanth", 1)
animationInfo.default = "slowSwim"

local keyframes = mj:enum {
    "idle",
    "lookLeft", 
    "lookRight",
}

animationInfo.animations = mj:indexed {
    slowSwim = {
        keyframes = {
            { keyframes.lookLeft, 1.5, {randomVariance = 0.2} },
            { keyframes.lookRight, 1.5, {randomVariance = 0.2} },
        },
    },
    fastSwim = {
        keyframes = {
            { keyframes.lookLeft, 0.5, {randomVariance = 0.2} },
            { keyframes.lookRight, 0.5, {randomVariance = 0.2} },
        },
    },
}

function animationInfo:initMainThread()
    
end

return animationInfo

