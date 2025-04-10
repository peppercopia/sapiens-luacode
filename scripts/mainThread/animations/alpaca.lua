local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"

local mainThreadAnimationGroup = {
}

local keyframes = mj:enum {
    "base1", 
    "headDownFull", 
    "headDownPart", 
    "walk1", 
    "walk2", 
    "walk3", 
    "walk4", 
    "walk5", 
    "walk6", 
    "base", 
    "lookLeft", 
    "lookRight", 
    "sit1", 
    "sit2", 
    "dead", 
    "die", 
}

local animationTypes = animationGroups.alpaca.animations

mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("alpaca", 1)
mainThreadAnimationGroup.default = animationTypes.stand1

local walkFrameDuration = 0.15

mainThreadAnimationGroup.animations = {
    [animationTypes.stand1] = {
        keyframes = {
            { keyframes.base1, 0.4 },
            { keyframes.headDownFull, 0.4 },
            { keyframes.headDownFull, 1.5 },
            { keyframes.headDownPart, 0.5 },
            { keyframes.headDownFull, 0.2 },
            { keyframes.headDownFull, 2.6 },
            { keyframes.headDownPart, 0.5 },
            { keyframes.headDownFull, 0.2 },
            { keyframes.headDownFull, 2.6 },
            { keyframes.base1,0.4 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 2.5 },
        }
    },
    [animationTypes.stand2] = {
        keyframes = {
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 1.2 },
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
            { keyframes.base1, 4.0 },
            { keyframes.base1, 1.0 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 1.2 },
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
            { keyframes.base1, 4.0 },
            { keyframes.base1, 1.0 },
            { keyframes.lookRight, 0.4 },
            { keyframes.lookRight, 1.2 },
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
        }
    },
    [animationTypes.stand3] = {
        keyframes = {
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
            { keyframes.lookRight, 0.4 },
            { keyframes.lookRight, 1.2 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 1.6 },
            { keyframes.lookLeft, 1.4 },
            { keyframes.base1, 0.4 },
            { keyframes.base1, 1.0 },
            { keyframes.headDownFull, 0.4 },
            { keyframes.headDownFull, 1.5 },
            { keyframes.headDownPart, 0.5 },
            { keyframes.headDownFull, 0.2 },
            { keyframes.headDownFull, 2.6 },
            { keyframes.headDownPart, 0.5 },
            { keyframes.headDownFull, 0.2 },
            { keyframes.headDownFull, 2.6 },
        }
    },
    [animationTypes.stand4] = {
        keyframes = {
            { keyframes.base1, 0.3 },
            { keyframes.headDownPart, 0.2 },
            { keyframes.headDownPart, 1.5 },
            { keyframes.headDownFull, 0.3 },
            { keyframes.headDownFull, 0.8 },
            { keyframes.headDownPart, 0.3 },
            { keyframes.headDownPart, 1.8 },
            { keyframes.headDownFull, 0.2 },
            { keyframes.headDownFull, 1.8 },
            { keyframes.base1, 0.3 },
            { keyframes.base1, 1.5 },
        }
    },
    [animationTypes.walk] = {
        keyframes = {
            { keyframes.walk1, walkFrameDuration },
            { keyframes.walk2, walkFrameDuration },
            { keyframes.walk3, walkFrameDuration },
            { keyframes.walk4, walkFrameDuration },
            { keyframes.walk5, walkFrameDuration },
            { keyframes.walk6, walkFrameDuration },
        }
    },
    [animationTypes.trot] = {
        keyframes = {
            { keyframes.walk1, walkFrameDuration * 2.0 },
            { keyframes.walk2, walkFrameDuration * 2.0 },
            { keyframes.walk3, walkFrameDuration * 2.0 },
            { keyframes.walk4, walkFrameDuration * 2.0 },
            { keyframes.walk5, walkFrameDuration * 2.0 },
            { keyframes.walk6, walkFrameDuration * 2.0 },
        }
    },
    [animationTypes.sit1] = {
        keyframes = {
            { keyframes.sit1, 0.3 },
            { keyframes.sit1, 1.5 },
        }
    },
    [animationTypes.sit2] = {
        keyframes = {
            { keyframes.sit2, 0.3 },
            { keyframes.sit2, 3.5 },
            { keyframes.sit2, 3.5 },
            { keyframes.sit1, 0.3 },
            { keyframes.sit1, 2.5 },
        }
    },
    [animationTypes.dead] = {
        keyframes = {
            { keyframes.dead, 0.3 },
            { keyframes.dead, 2.5 },
        }
    },
    [animationTypes.die] = {
        keyframes = {
            { keyframes.die, 0.3 },
            { keyframes.dead, 0.3 },
            { keyframes.dead, 2.5 },
            { keyframes.dead, 2.5 },
            { keyframes.dead, 2.5 },
        }
    },
}

return mainThreadAnimationGroup
