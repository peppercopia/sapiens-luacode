local model = mjrequire "common/model"

local animationInfo = {}

animationInfo.modelTypeIndex = model:modelIndexForModelNameAndDetailLevel("chicken", 1)
animationInfo.default = "lookRight"

local keyframes = mj:enum {
    "base", 
    "jaw", 
    "walk1",
    "walk2",
    "walk3",
    "walk4",
    "walk5_pad",
    "run1",
    "run2",
    "run3",
    "run4",
    "run5",
    "run6",
    "peck1",
    "peck2",
    "peck3",
    "peck4",
    "lookLeft",
    "lookRight",
    "die",
    "dead",
    "scratch1",
    "scratch2",
    "scratch3",
    "scratch4",
    "scratch5",
    "scratch6",
    "scratch7",
    "scratch8",
    "scratch9",
    "scratch10",
    "scratch11",
    "scratch12",
}


animationInfo.animations = mj:indexed {
    stand1 = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.lookRight, 1.5 },
        },
    },
    lookRight = {
        keyframes = {
            { keyframes.base, 1.5 },
            { keyframes.lookRight, 0.2 },
            { keyframes.lookRight, 1.0 },
            { keyframes.peck1, 0.2 },
            { keyframes.peck1, 0.4, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.2, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.2, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.6, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 1.0, { randomVariance = 0.4 } },
            { keyframes.lookRight, 0.2, { randomVariance = 0.4 } },
            { keyframes.lookRight, 1.0, { randomVariance = 0.4 } },
            { keyframes.base, 0.2 },
        },
    },
    walk = {
        keyframes = {
            { keyframes.walk1, 0.3 },
            { keyframes.walk2, 0.3 },
            { keyframes.walk3, 0.3 },
            { keyframes.walk4, 0.3 },
        },
    },
    run = {
        keyframes = {
            { keyframes.run1, 0.5 },
            { keyframes.run2, 0.5 },
            { keyframes.run3, 0.5 },
            { keyframes.run4, 0.5 },
            { keyframes.run5, 0.5 },
            { keyframes.run6, 0.5 },
        },
    },
    die = {
        keyframes = {
            { keyframes.die, 0.1 },
            { keyframes.dead, 0.1 },
        }
    },
    dead = {
        keyframes = {
            { keyframes.dead, 0.5 },
        },
    },
    scratch1 = {
        keyframes = {
            { keyframes.peck1, 0.23 },
            { keyframes.peck2, 0.15, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.08, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.03, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.27, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.05, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.15, { randomVariance = 0.4 }},
            { keyframes.peck1, 0.21, { randomVariance = 0.4 } },
            { keyframes.base, 0.15, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.07, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.3, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.3, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.2, { randomVariance = 0.4 } },
            { keyframes.base, 0.9, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.2, { randomVariance = 0.4 } },
            { keyframes.lookRight, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookRight, 0.8, { randomVariance = 0.4 } },
        },
    },
    scratch2 = {
        keyframes = {
            { keyframes.scratch5, 0.13 },
            { keyframes.scratch6, 0.25, { randomVariance = 0.04 } },
            { keyframes.scratch7, 0.28, { randomVariance = 0.04 } },
            { keyframes.scratch8, 0.23, { randomVariance = 0.04 } },
            { keyframes.scratch9, 0.23, { randomVariance = 0.04 } },
            { keyframes.scratch10, 0.23, { randomVariance = 0.04 } },
            { keyframes.scratch11, 0.23, { randomVariance = 0.04 } },
            { keyframes.scratch12, 0.23, { randomVariance = 0.04 } },
            { keyframes.scratch5, 0.13, { randomVariance = 0.40 } },
            { keyframes.peck4, 0.05, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.15, { randomVariance = 0.4 }},
            { keyframes.peck1, 0.21, { randomVariance = 0.4 } },
            { keyframes.scratch1, 0.23, { randomVariance = 0.4 } },
            { keyframes.scratch2, 0.15, { randomVariance = 0.4 } },
            { keyframes.scratch3, 0.28, { randomVariance = 0.4 } },
            { keyframes.scratch4, 0.13, { randomVariance = 0.4 } },
            { keyframes.base, 0.15, { randomVariance = 0.4 } },
            { keyframes.peck1, 0.21, { randomVariance = 0.4 } },
            { keyframes.base, 0.15, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.07, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.3, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.1, { randomVariance = 0.4 } },
            { keyframes.base, 0.15 },
        },
    },
    scratch3 = {
        keyframes = {
            { keyframes.scratch1, 0.23, { randomVariance = 0.4 } },
            { keyframes.scratch2, 0.15, { randomVariance = 0.4 } },
            { keyframes.scratch3, 0.28, { randomVariance = 0.4 } },
            { keyframes.scratch4, 0.13, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.3, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.2, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.27, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.05, { randomVariance = 0.4 } },
            { keyframes.peck4, 0.1, { randomVariance = 0.4 } },
            { keyframes.peck2, 0.15, { randomVariance = 0.4 }},
            { keyframes.peck1, 0.21, { randomVariance = 0.4 } },
            { keyframes.base, 0.15, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.1, { randomVariance = 0.4 } },
            { keyframes.lookLeft, 0.3, { randomVariance = 0.4 } },
            { keyframes.peck3, 0.2, { randomVariance = 0.4 } },
            { keyframes.base, 0.9 },
        },
    },
    sit = {
        keyframes = {
            { keyframes.base, 1.0, {randomVariance = 0.4} },
            { keyframes.lookLeft, 1.0, {randomVariance = 0.4} },
        }
    },
}

function animationInfo:initMainThread()
    
end

return animationInfo