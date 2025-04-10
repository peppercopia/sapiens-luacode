
local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"
--local rng = mjrequire "common/randomNumberGenerator"

local mainThreadAnimationGroup = {

}

local keyframes = mj:enum {
    "idle",
    "lookLeft", 
    "lookRight",
}


local animationTypes = animationGroups.catfish.animations

mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("catfish", 1)
mainThreadAnimationGroup.default = animationTypes.slowSwim


mainThreadAnimationGroup.animations = {
    [animationTypes.slowSwim] = {
        keyframes = {
            { keyframes.lookLeft, 1.5 },
            { keyframes.lookRight, 1.5 },
        },
    },
    [animationTypes.fastSwim] = {
        keyframes = {
            { keyframes.lookLeft, 0.5 },
            { keyframes.lookRight, 0.5 },
        },
    },
}

return mainThreadAnimationGroup
