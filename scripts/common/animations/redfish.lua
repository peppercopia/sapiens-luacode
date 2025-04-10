local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("redfish", 1)
animationInfo.default = "slowSwim"

local keyframes = mj:enum {
    "idle",
    "lookLeft", 
    "lookRight",
}

animationInfo.animations = mj:indexed {
    slowSwim = {
        keyframes = {
            { keyframes.lookLeft, 0.75, {randomVariance = 0.1} },
            { keyframes.lookRight, 0.75, {randomVariance = 0.1} },
        },
    },
    fastSwim = {
        keyframes = {
            { keyframes.lookLeft, 0.25, {randomVariance = 0.1} },
            { keyframes.lookRight, 0.25, {randomVariance = 0.1} },
        },
    },
}

function animationInfo:initMainThread()
    
end

return animationInfo