
local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"
--local rng = mjrequire "common/randomNumberGenerator"

local mainThreadAnimationGroup = {

}

local keyframes = mj:enum {
    "base", 
    "base2", 
    "lookRight",
    "lookDown",
    "twistLeft",
    "peckLeft",
    "flap",
    "walk1",
    "walk2",
    "walk3",
    "walk4",
    "death1",
    "death2",
    "death3",
    "scratch1",
    "scratch2",
    "scratch3",
    "scratch4",
    "peckWalk1",
    "peckWalk2",
    "peckWalk3",
    "peckWalk4",
    "peck",
    "run1",
    "run2",
    "run3",
    "run4",
    "sit1",
    "sit2",
}


local animationTypes = animationGroups.chicken.animations

mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("chicken", 1)
mainThreadAnimationGroup.default = animationTypes.lookRight


mainThreadAnimationGroup.animations = {
    [animationTypes.stand1] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.lookRight, 1.5 },
        },
    },
    [animationTypes.lookRight] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 1.0 },
            { keyframes.lookDown, 0.2 },
            { keyframes.lookDown, 0.4 },
            { keyframes.twistLeft, 0.2 },
            { keyframes.peckLeft, 0.1 },
            { keyframes.twistLeft, 0.2 },
            { keyframes.twistLeft, 0.6 },
            { keyframes.peckLeft, 0.1 },
            { keyframes.lookDown, 0.1 },
            { keyframes.lookDown, 1.0 },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 1.0 },
            { keyframes.base, 0.2 },
        },
    },
    [animationTypes.walk] = {
        keyframes = {
            { keyframes.walk1, 0.2 },
            { keyframes.walk2, 0.2 },
            { keyframes.walk3, 0.2 },
            { keyframes.walk4, 0.2 },
        },
    },
    [animationTypes.run] = {
        keyframes = {
            { keyframes.run1, 0.4 },
            { keyframes.run2, 0.4 },
            { keyframes.run3, 0.4 },
            { keyframes.run4, 0.4 },
        },
    },
    [animationTypes.die] = {
        keyframes = {
            { keyframes.death1, 0.1 },
            { keyframes.death2, 0.1 },
            { keyframes.death3, 0.1 },
            { keyframes.death3, 1.0 },
            { keyframes.death3, 1.0 },
            { keyframes.death3, 1.0 },
            { keyframes.death3, 1.0 },
            { keyframes.death3, 1.0 },
        },
    },
    [animationTypes.dead] = {
        keyframes = {
            { keyframes.death3, 0.5 },
        },
    },
    [animationTypes.scratch] = {
        keyframes = {
            { keyframes.scratch1, 0.23 },
            { keyframes.scratch2, 0.15 },
            { keyframes.scratch3, 0.08 },
            { keyframes.scratch4, 0.03 },
            { keyframes.scratch2, 0.27 },
            { keyframes.scratch3, 0.1 },
            { keyframes.scratch4, 0.05 },
            { keyframes.scratch4, 0.1 },
            { keyframes.scratch2, 0.15 },
            { keyframes.scratch1, 0.21 },
            { keyframes.peckWalk2, 0.15 },
            { keyframes.lookDown, 0.07 },
            { keyframes.lookDown, 0.3 },
            { keyframes.peck, 0.1 },
            { keyframes.lookDown, 0.1 },
            { keyframes.lookDown, 0.3 },
            { keyframes.twistLeft, 0.2 },
            { keyframes.twistLeft, 0.9 },
            { keyframes.peckLeft, 0.1 },
            { keyframes.twistLeft, 0.2 },
            { keyframes.lookDown, 0.1 },
            { keyframes.lookDown, 0.8 },
        },
    },
    [animationTypes.sit] = {
        keyframes = {
            { keyframes.sit1, 1.0, {randomVariance = 0.4} },
            { keyframes.sit2, 1.0, {randomVariance = 0.4} },
        }
    },
}

return mainThreadAnimationGroup
