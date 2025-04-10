

local model = mjrequire "common/model"
local animationGroups = mjrequire "common/animations/animationGroups"
local rng = mjrequire "common/randomNumberGenerator"
local audio = mjrequire "mainThread/audio"

local mainThreadAnimationGroup = {
}

local keyframes = mj:enum {
    "headMove1", 
    "headMove2", 
    "headMove3", 
    "walk1", 
    "walk2", 
    "walk3", 
    "walk4", 
    "walk5", 
    "walk6", 
    "base", 
    "agroUp", 
    "agroDown1", 
    "agroDown2", 
    "agroDown3", 
    "agroDown4", 
    "agroWalk1", 
    "agroWalk2", 
    "agroWalk3", 
    "agroWalk4", 
    "agroWalk5", 
    "agroWalk6", 
    "sleep1", 
    "sleep2", 
    "sleep3", 
    "sleep4", 
    "dead",
    "die",
}


local animationTypes = animationGroups.mammoth.animations

mainThreadAnimationGroup.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("mammoth", 1)
mainThreadAnimationGroup.default = animationTypes.stand1

local stepIndex = 1
local function playRandomSound(pos, name, max)
    local pitchOffset = 1.0 + (rng:randomValue() - 0.5) * 0.2
    if audio:playWorldSound("audio/sounds/" .. name .. mj:tostring(stepIndex) .. ".wav", pos, nil, pitchOffset, 130) then
        stepIndex = stepIndex + 1
        if rng:randomBool() then
            stepIndex = stepIndex + 1
        end

        if stepIndex > max then
            stepIndex = (stepIndex % max) + 1
        end
    end
end

local function stepTrigger(objectPos)
    playRandomSound(objectPos, "elephantStep", 4)
end


local walkFrameDuration = 0.3

mainThreadAnimationGroup.animations = {
    [animationTypes.stand1] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.headMove3, 1.5 },
            { keyframes.headMove1, 1.5 },
            { keyframes.base, 1.5 },
        }
    },
    [animationTypes.stand2] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.headMove1, 1.5 },
            { keyframes.headMove2, 1.5 },
            { keyframes.base, 1.5 },
        }
    },
    [animationTypes.stand3] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.headMove2, 1.5 },
            { keyframes.headMove3, 1.5 },
            { keyframes.base, 1.5 },
        }
    },
    [animationTypes.stand4] = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.headMove2, 1.5 },
            { keyframes.headMove3, 1.0 },
            { keyframes.headMove1, 0.5 },
            { keyframes.base, 1.5 },
        }
    },
    [animationTypes.walk] = {
        keyframes = {
            { keyframes.walk1, walkFrameDuration, {randomVariance = 0.3} },
            { keyframes.walk2, walkFrameDuration * 1.5, { trigger = stepTrigger } },
            { keyframes.walk3, walkFrameDuration, {randomVariance = 0.3, trigger = stepTrigger} },
            { keyframes.walk4, walkFrameDuration, { trigger = stepTrigger } },
            { keyframes.walk5, walkFrameDuration, {randomVariance = 0.3} },
            { keyframes.walk6, walkFrameDuration, { trigger = stepTrigger } },
        }
    },
    [animationTypes.agroWalk] = {
        keyframes = {
            { keyframes.agroWalk1, walkFrameDuration, {randomVariance = 0.5} },
            { keyframes.agroWalk2, walkFrameDuration, { trigger = stepTrigger } },
            { keyframes.agroWalk3, walkFrameDuration, {randomVariance = 0.1} },
            { keyframes.agroWalk4, walkFrameDuration, { trigger = stepTrigger } },
            { keyframes.agroWalk5, walkFrameDuration, {randomVariance = 0.1} },
            { keyframes.agroWalk6, walkFrameDuration, { trigger = stepTrigger } },
        }
    },
    [animationTypes.attack] = {
        keyframes = {
            { keyframes.agroUp, 1.5 },
            { keyframes.agroDown1, 1.5 },
            { keyframes.agroDown2, 1.0 },
            { keyframes.agroDown3, 0.5 },
        }
    },
    [animationTypes.agro1] = {
        keyframes = {
            { keyframes.agroDown2, 1.0, {randomVariance = 0.4} },
            { keyframes.agroDown3, 1.0, {randomVariance = 0.4} },
            { keyframes.agroDown4, 1.0, {randomVariance = 0.4} },
            { keyframes.agroDown3, 0.5, {randomVariance = 0.1} },
        }
    },
    [animationTypes.sleep1] = {
        keyframes = {
            { keyframes.sleep1, 1.0, {randomVariance = 0.4} },
            { keyframes.sleep2, 1.0, {randomVariance = 0.4} },
        }
    },
    [animationTypes.sleep2] = {
        keyframes = {
            { keyframes.sleep3, 1.0, {randomVariance = 0.4} },
            { keyframes.sleep4, 1.0, {randomVariance = 0.4} },
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
            { keyframes.dead, 2.5 },
        }
    },

    
}

return mainThreadAnimationGroup