

local model = mjrequire "common/model"
local rng = mjrequire "common/randomNumberGenerator"
local audio = nil --only available mainThread

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("mammoth", 1)
animationInfo.default = "stand1"

local keyframes = mj:enum {
    "base", 
    "walk1", 
    "walk2", 
    "walk3", 
    "walk4",
    "charge1", 
    "charge2", 
    "charge3", 
    "charge4",
    "left", 
    "right",
    "agro1", 
    "agro2", 
    "agro3", 
    "agroLeft1", 
    "agroLeft2", 
    "agroLeft3", 
    "agroRight1", 
    "agroRight2", 
    "agroRight3", 
    "agroDown1", 
    "agroDown2", 
    "agroDown3", 
    "unused_1", 
    "eat1", 
    "eat2", 
    "sleep", 
    "die",
    "dead",
}

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


local walkFrameDuration = 0.35
local chargeFrameDuration = 0.8

animationInfo.animations = mj:indexed {
    stand1 = {
        keyframes = {
            { keyframes.base, 1.2 },
            { keyframes.left, 2.0 },
            { keyframes.left, 1.2 },
            { keyframes.eat2, 1.6 },
            { keyframes.agroDown3, 2.0 },
            { keyframes.agroDown3, 1.2 },
            { keyframes.base, 2.0 },
            { keyframes.eat2, 1.6 },
        }
    },
    stand2 = {
        keyframes = {
            { keyframes.base, 1.2 },
            { keyframes.right, 2.0 },
            { keyframes.left, 1.2 },
            { keyframes.eat1, 1.6 },
            { keyframes.right, 1.2 },
            { keyframes.base, 2.0 },
        }
    },
    stand3 = {
        keyframes = {
            { keyframes.base, 1.2 },
            { keyframes.left, 2.0 },
            { keyframes.right, 1.2 },
            { keyframes.left, 1.6 },
            { keyframes.left, 1.2 },
            { keyframes.base, 2.0 },
        }
    },
    stand4 = {
        keyframes = {
            { keyframes.base, 1.2 },
            { keyframes.agroDown3, 2.0 },
            { keyframes.eat1, 1.6 },
            { keyframes.eat2, 1.6 },
            { keyframes.eat2, 1.8 },
            { keyframes.eat2, 1.6 },
            { keyframes.eat1, 1.6 },
            { keyframes.right, 1.2 },
            { keyframes.left, 1.6 },
        }
    },
    walk = {
        keyframes = {
            { keyframes.walk1, walkFrameDuration, {randomVariance = 0.3} },
            { keyframes.walk2, walkFrameDuration * 1.5, { trigger = stepTrigger } },
            { keyframes.walk3, walkFrameDuration, {randomVariance = 0.3, trigger = stepTrigger} },
            { keyframes.walk4, walkFrameDuration, { trigger = stepTrigger } },
        }
    },
    agroWalk = {
        keyframes = {
            { keyframes.charge1, chargeFrameDuration, {randomVariance = 0.5} },
            { keyframes.charge2, chargeFrameDuration, { trigger = stepTrigger } },
            { keyframes.charge3, chargeFrameDuration, {randomVariance = 0.1} },
            { keyframes.charge4, chargeFrameDuration, { trigger = stepTrigger } },
        }
    },
    attack = {
        keyframes = {
            { keyframes.agroDown1, 0.5 },
            { keyframes.agroLeft1, 0.5 },
            { keyframes.agroLeft2, 0.5 },
            { keyframes.agroLeft3, 0.5 },
            { keyframes.agroRight1, 0.5 },
            { keyframes.agroRight2, 0.5 },
            { keyframes.agroRight3, 0.5 },
        }
    },
    agro1 = {
        keyframes = {
            { keyframes.agroLeft1, 2.0, {randomVariance = 1.4} },
            { keyframes.agroLeft1, 0.4, {randomVariance = 0.4} },
            { keyframes.agroLeft2, 2.0, {randomVariance = 1.4} },
            { keyframes.agroLeft2, 0.4, {randomVariance = 0.4} },
            { keyframes.agroLeft3, 2.0, {randomVariance = 1.4} },
            { keyframes.agroLeft3, 0.4, {randomVariance = 0.4} },
        }
    },
    sleep1 = {
        keyframes = {
            { keyframes.sleep, 1.0, {randomVariance = 0.4} },
            { keyframes.sleep, 1.0, {randomVariance = 0.4} },
        }
    },
    dead = {
        keyframes = {
            { keyframes.dead, 0.3 },
            { keyframes.dead, 2.5 },
        }
    },
    die = {
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

function animationInfo:initMainThread()
    --mainThreadParticleManagerInterface = mjrequire "mainThread/mainThreadParticleManagerInterface"
    audio = mjrequire "mainThread/audio"
end

return animationInfo