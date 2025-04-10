local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3

local model = mjrequire "common/model"
local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("alpaca", 1)
animationInfo.default = "stand1"

local keyframes = mj:enum {
    "base",
    "jaw",
    "walk1", 
    "walk2", 
    "walk3", 
    "walk4", 
    "walk5", 
    "walk6", 
    "unuseda", 
    "unusedb", 
    "lookLeft", 
    "lookRight",
    "eat1",
    "eat2",
    "sit1", 
    "sit2", 
    "spit1", 
    "spit2", 
    "die", 
    "dead", 
    "gallop1", 
    "gallop2", 
    "gallop3", 
    "gallop4", 
}


local jawBoneNames = {
    "jaw",
}

--[[local earBoneNames = {
    "lear", "rear",
}]]

local mouthOpenComposite = {
    frame = keyframes.jaw,
    bones = jawBoneNames,
}

--[[local earsBackComposite = {
    frame = keyframes.spit2,
    bones = earBoneNames,
}]]

local randomBodyRotation = {
    neck1 = vec3(0.1,0.1,0.1) --yaw,pitch,roll each frame will get assigned a random rotation from -x radians to +x --- NOT YET IMPLEMENTED !!!!!!!!!!!!!!!!!!!
}


local walkFrameDuration = 0.3
local gallopFrameDuration = 1.0

animationInfo.animations = mj:indexed {
    stand1 = {
        keyframes = {
            { keyframes.base, 0.4 },
            { keyframes.base, 0.2 },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.4 },
            { keyframes.base, 0.4 },
            { keyframes.base, 1.0 },
            { keyframes.base, 4.0 },
            { keyframes.base,0.2 },
            { keyframes.lookRight, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookRight, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookRight, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookRight, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookRight, 0.4 },
            { keyframes.base, 0.2 },
            { keyframes.base, 1.0 },
            { keyframes.base, 4.0 },
            { keyframes.base, 0.2 },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.2 },
            { keyframes.lookLeft, 0.1, {composites = {mouthOpenComposite}} },
            { keyframes.lookLeft, 2.0, {randomVariance = 4.0, randomRotations = randomBodyRotation} },
            { keyframes.lookLeft, 0.4 },
            { keyframes.base, 0.2 },
            { keyframes.base, 1.0 },
        }
    },
    
    graize1 = {
        keyframes = {
            { keyframes.base, 0.4 },
            { keyframes.eat1, 0.4 },
            { keyframes.eat1, 1.5 },
            { keyframes.eat2, 0.5 },
            { keyframes.eat1, 0.2 },
            { keyframes.eat1, 2.6 },
            { keyframes.eat2, 0.5 },
            { keyframes.eat1, 0.2 },
            { keyframes.eat1, 2.6 },
            { keyframes.base,0.4 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 2.5 },
        }
    },
    graize2 = {
        keyframes = {
            { keyframes.base, 0.4 },
            { keyframes.base, 1.0 },
            { keyframes.lookRight, 0.4 },
            { keyframes.lookRight, 1.2 },
            { keyframes.lookLeft, 0.4 },
            { keyframes.lookLeft, 1.6 },
            { keyframes.lookLeft, 1.4 },
            { keyframes.base, 0.4 },
            { keyframes.base, 1.0 },
            { keyframes.eat1, 0.4 },
            { keyframes.eat1, 1.5 },
            { keyframes.eat2, 0.5 },
            { keyframes.eat1, 0.2 },
            { keyframes.eat1, 2.6 },
            { keyframes.eat2, 0.5 },
            { keyframes.eat1, 0.2 },
            { keyframes.eat1, 2.6 },
        }
    },
    graize3 = {
        keyframes = {
            { keyframes.base, 0.3 },
            { keyframes.eat2, 0.2 },
            { keyframes.eat2, 1.5 },
            { keyframes.eat1, 0.3 },
            { keyframes.eat1, 0.8 },
            { keyframes.eat2, 0.3 },
            { keyframes.eat2, 1.8 },
            { keyframes.eat1, 0.2 },
            { keyframes.eat1, 1.8 },
            { keyframes.base, 0.3 },
            { keyframes.base, 1.5 },
        }
    },

    walk = {
        keyframes = {
            { keyframes.walk1, walkFrameDuration },
            { keyframes.walk2, walkFrameDuration },
            { keyframes.walk3, walkFrameDuration },
            { keyframes.walk4, walkFrameDuration },
            { keyframes.walk5, walkFrameDuration },
            { keyframes.walk6, walkFrameDuration },
        }
    },
    gallop = {
        keyframes = {
            { keyframes.gallop1, gallopFrameDuration },
            { keyframes.gallop2, gallopFrameDuration },
            { keyframes.gallop3, gallopFrameDuration },
            { keyframes.gallop4, gallopFrameDuration },
        }
    },
    sit1 = {
        keyframes = {
            { keyframes.sit1, 0.3 },
            { keyframes.sit1, 1.5 },
        }
    },
    sit2 = {
        keyframes = {
            { keyframes.sit2, 0.3 },
            { keyframes.sit2, 3.5 },
            { keyframes.sit2, 3.5 },
            { keyframes.sit1, 0.3 },
            { keyframes.sit1, 2.5 },
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
        }
    },
}

function animationInfo:initMainThread()

end

return animationInfo

