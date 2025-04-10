local mjm = mjrequire "common/mjm"
local mat3Identity = mjm.mat3Identity
local mat3GetRow = mjm.mat3GetRow

local rng = mjrequire "common/randomNumberGenerator"

local mainThreadParticleManagerInterface = nil --only available mainThread
local audio = nil --only available mainThread

-- notes
-- randomVariance is added to the base time. result = duration + randomFloatBetweenZeroAndOne * randomVariance

local sapienCommon = {

}

local keyframes = mj:enum {
    "walk1_old", 
    "walk2_old", 
    "pickup", 
    "stand", 
    "stand_carry", 
    "walk_carry1_OLD", 
    "walk_carry2_OLD", 
    "stand_breathe", 
    "hand_hip", 
    "hand_hip_breathe", 
    "crouch", 
    "hands_and_knees", 
    "sleep_start1", 
    "sleep_start2", 
    "sleep_start3", 
    "sleep", 
    "walk1", 
    "walk2", 
    "walk3", 
    "walk4", 
    "walk5", 
    "walk6", 
    "walk7", 
    "walk8", 
    "reachUp1", 
    "reachUp2", 
    "reachUp3", 
    "chop1", 
    "chop2", 
    "chop3", 
    "chop4",
    "smallCarry", 
    "pickupSmallCarry", 
    "addToSmallCarry", 
    "knap1", 
    "knap2", 
    "crouchSmallCarry", 
    "knapLook", 
    "light3", 
    "wave1", 
    "wave2",
    "wave3",
    "light1",
    "light2",
    "kick1",
    "kick2",
    "knap3", 
    "knapCrude2", 
    "knapCrude3", 
    "knapCrude1", 
    "sneak5_old", 
    "sneak6_old", 
    "sneak7_old", 
    "sneak8_old", 
    "standCarrySingle_old", 
    "throwAim", 
    "throw1", 
    "throw2", 
    "throw3", 
    "sitFocus",
    "highCarry",
    "highSmallCarry",
    "highMediumCarry",
    "pickupHighSmallCarry",
    "addToHighSmallCarry",
    "pickupHighMediumCarry",
    "addToHighMediumCarry",
    "jog7_old",
    "jog8_old",
    "pickupHighCarry",
    "addToHighCarry",
    "scrape1",
    "scrape2",
    "scrapeLook1",
    "scrapeLook2",
    "fireStickCook1",
    "fireStickCook2",
    "fireStickCook3",
    "happy",
    "closedEyes",
    "eat1",
    "eat2",
    "eat3",
    "eat4",
    "sneakStand",
    "slowWalk1",
    "slowWalk2",
    "slowWalk3",
    "slowWalk4",
    "slowWalk5",
    "slowWalk6",
    "slowWalk7",
    "slowWalk8",
    "slowWalkPad",
    "sadWalk1",
    "sadWalk2",
    "sadWalk3",
    "sadWalk4",
    "sadWalk5",
    "sadWalk6",
    "sadWalk7",
    "sadWalk8",
    "sadWalkPad",
    "pullWeeds1",
    "pullWeeds2",
    "pullWeeds3",
    "pullWeeds4",
    "sneak1", 
    "sneak2", 
    "sneak3", 
    "sneak4", 
    "sneak5", 
    "sneak6", 
    "sneak7", 
    "sneak8", 
    "sneakPad", 
    "crouchLow",
    "sit1", 
    "sit2", 
    "sit3", 
    "sit4",
    "jog1",
    "jog2",
    "jog3",
    "jog4",
    "jog5",
    "jog6",
    "jog7",
    "jog8",
    "jogPad",
    "sitLowSeat1",
    "patDown1",
    "patDown2",
    "patDown3",
    "inspect1",
    "inspect2",
    "inspect3",
    "crouchDig1",
    "crouchDig2",
    "crouchDig3",
    "crouchDig4",
    "pottery1",
    "pottery2",
    "pottery3",
    "pottery4",
    "thresh1",
    "thresh2",
    "thresh3",
    "thresh4",
    "grumpyFace",
    "fall1",
    "fall2",
    "fall3",
    "fall4",
    "fall5",
    "fall6",
    "fall7",
    "fall8",
    "swim1",
    "swim2",
    "swim3",
    "swim4",
    "swim5",
    "treadWater1",
    "treadWater2",
    "playFlute1",
    "playFlute2",
    "playDrum1",
    "playDrum2",
    "playDrum3",
    "gatherBush1",
    "gatherBush2",
    "gatherBush3",
    "gatherBush4",
    "grind1", --175
    "grind2",
    "grind3",
    "grind4",
    "medicine1", --179
    "medicine2",
    "medicine3",
    "medicine4",
    "medicine5",
    "smithHammer1",
    "smithHammer2",
    "smithHammer3",
    "smithLook",
    "chisel1", --188
    "chisel2",
    "chisel3",
    "chisel4",
    "dragObjectWalk1",
    "dragObjectWalk2",
    "dragObjectWalk3",
    "dragObjectWalk4",
    "dragObjectWalk5",
    "dragObjectWalk6",
    "dragObjectWalk7",
    "dragObjectWalk8",
    "dragObjectWalkPad", --200
    "row1",
    "row2",
    "row3",
    "row4",
}

local stepIndex = 1

local function playRandomSound(pos, name, max, priorityOrNil)
    stepIndex = stepIndex + 1
    if rng:randomBool() then
        stepIndex = stepIndex + 1
    end

    if stepIndex > max then
        stepIndex = (stepIndex % max) + 1
    end

    audio:playWorldSound("audio/sounds/" .. name .. mj:tostring(stepIndex) .. ".wav", pos, nil, nil, priorityOrNil)
end

local function stepTrigger(objectPos, objectRotation, covered)
    playRandomSound(objectPos, "step", 4, 130)
end

local function eatTrigger(objectPos, objectRotation, covered)
    playRandomSound(objectPos, "eat", 2, nil)
end

local function kickTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.destroy, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.5), objectRotation, nil, covered)
    audio:playWorldSound("audio/sounds/kick1.wav", objectPos)
end

local function chopTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.woodChop, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(1.2) + mat3GetRow(objectRotation, 1) * mj:mToP(0.5), mat3Identity, nil, covered)
    audio:playWorldSound("audio/sounds/chop1.wav", objectPos)
end

local function mineTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.woodChop, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(1.2) + mat3GetRow(objectRotation, 1) * mj:mToP(0.1), mat3Identity, nil, covered)
    audio:playWorldSound("audio/sounds/mine1.wav", objectPos)
end

local function digTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.dig, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.5), mat3Identity, nil, covered)
    audio:playWorldSound("audio/sounds/dig.wav", objectPos)
end

local function pullWeedsTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.pullWeeds, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.5) + mat3GetRow(objectRotation, 1) * mj:mToP(0.2), objectRotation, nil, covered)
    audio:playWorldSound("audio/sounds/whoosh1.wav", objectPos)
end

local function knapTrigger(objectPos, objectRotation, covered)
    audio:playWorldSound("audio/sounds/knap1.wav", objectPos)
end

local function smithHammerTrigger(objectPos, objectRotation, covered)
    audio:playWorldSound("audio/sounds/smithHammer1.wav", objectPos)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.blacksmithSparks, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.5), mat3Identity, nil, covered)
    
end

local function chiselTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.woodChop, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.2) + mat3GetRow(objectRotation, 1) * mj:mToP(0.1), mat3Identity, nil, covered)
    playRandomSound(objectPos, "chisel", 5, nil)
end


local function grindTrigger(objectPos, objectRotation, covered)
    audio:playWorldSound("audio/sounds/grind1.wav", objectPos)
end

local function threshTrigger(objectPos, objectRotation, covered)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.pullWeeds, objectPos + mat3GetRow(objectRotation, 2) * mj:mToP(0.5) + mat3GetRow(objectRotation, 1) * mj:mToP(0.2), objectRotation, nil, covered)
    audio:playWorldSound("audio/sounds/thresh.wav", objectPos)
end

local function scrapeTrigger(objectPos, objectRotation, covered)
    audio:playWorldSound("audio/sounds/scrape1.wav", objectPos)
end


local function rowTrigger(objectPos, objectRotation, covered)
    --audio:playWorldSound("audio/sounds/splash1.wav", objectPos)
    mainThreadParticleManagerInterface:addEmitter(mainThreadParticleManagerInterface.emitterTypes.waterSplash, objectPos + mat3GetRow(objectRotation, 0) * mj:mToP(0.5), objectRotation, nil, covered)
    playRandomSound(objectPos, "splash", 5, nil)
end

local walkFrameDuration = 0.125
local sneakFrameDuration = 0.14
local jogFrameDuration = 0.09
local runFrameDuration = 0.09 / 1.6
local slowWalkFrameDuration = 0.15
local sadWalkFrameDuration = 0.15
local dragObjectWalkFrameDuration = 0.15

local drumPlaySpeedFast = 0.1
local drumPlaySpeedSlow = 0.3


local leftArmBoneNames = {
    "arm1.L", "arm2.L",
}

local rightArmBoneNames = {
    "arm1.R", "arm2.R",
}

local standardCarryBoneNames = {
    "arm1.L", "arm2.L",
    "arm1.R", "arm2.R",
    "back",
}

local faceBoneNames = {
    "eyelids", "mouthCorners", "jaw", "eyebrows",
}

local highCarryComposite = {
    frame = keyframes.highCarry,
    bones = leftArmBoneNames,
}

local highSmallCarryComposite = {
    frame = keyframes.highSmallCarry,
    bones = leftArmBoneNames,
}

local highMediumCarryComposite = {
    frame = keyframes.highMediumCarry,
    bones = leftArmBoneNames,
}

local smallCarryComposite = {
    frame = keyframes.smallCarry,
    bones = leftArmBoneNames,
}

local standardCarryComposite = {
    frame = keyframes.stand_carry,
    bones = standardCarryBoneNames,
}

local waveComposite = {
    frame = keyframes.wave3,
    bones = mj:concatTables(rightArmBoneNames,faceBoneNames),
}

local grumpyComposite = {
    frame = keyframes.grumpyFace,
    bones = faceBoneNames,
}

local leftHitDrum = {
    frame = keyframes.playDrum2,
    bones = leftArmBoneNames,
}
local rightHitDrum = {
    frame = keyframes.playDrum2,
    bones = rightArmBoneNames,
}

function sapienCommon:setup(animationInfo, walkSpeedMultiplier)
    
    animationInfo.default = "stand"

    local walkDurationMultipier = 1.0 / walkSpeedMultiplier
    animationInfo.animations = mj:indexed {
        stand = {
            keyframes = {
                {keyframes.stand, 0.2},
                {keyframes.stand_breathe, 1.5},
                {keyframes.stand, 1.5},
           },
       },
        standCarry = {
            keyframes = {
                {keyframes.stand_carry, 0.2},
           },
       },
        pickup = {
            keyframes = {
                {keyframes.pickup, 0.4},
           },
       },
        place = {
            keyframes = {
                {keyframes.pickup, 0.4},
           },
       },
        sleep_test = {
            keyframes = {
                {keyframes.stand_breathe, 0.5},
                {keyframes.stand, 0.5},
                {keyframes.stand_breathe, 0.5},
                {keyframes.stand, 0.5},
                {keyframes.stand_breathe, 0.5},
                {keyframes.stand, 0.5},
                --{keyframes.hands_and_knees, 0.89},
                {keyframes.sleep_start1, 1.0},
                {keyframes.sleep_start3, 1.2},
                {keyframes.sleep, 2.0},
                {keyframes.sleep, 4.0},
                {keyframes.sleep, 4.0},
                {keyframes.sleep, 4.0},
                {keyframes.sleep, 4.0},
                {keyframes.sleep_start3, 0.34},
                {keyframes.hands_and_knees, 0.6},
                {keyframes.crouch, 0.5},
                {keyframes.stand, 0.4},
           },
       },
        reachUp = {
            proceduralType = 1,
            keyframes = {
                {keyframes.reachUp1, 0.3, {randomVariance = 0.1}},
                {keyframes.reachUp1, 0.5, {randomVariance = 0.1}},
                {keyframes.reachUp2, 0.5, {randomVariance = 0.1}},
                {keyframes.reachUp3, 0.3, {randomVariance = 0.1}},
           },
       },
        gatherBush = {
            proceduralType = 1,
            keyframes = {
                {keyframes.gatherBush1, 0.3, {randomVariance = 0.3}},
                {keyframes.gatherBush2, 0.5, {randomVariance = 0.4}},
                {keyframes.gatherBush1, 0.5, {randomVariance = 0.4}},
                {keyframes.gatherBush1, 0.1, {randomVariance = 0.3}},
                {keyframes.gatherBush2, 0.3, {randomVariance = 0.3}},
                {keyframes.gatherBush3, 0.5, {randomVariance = 0.8}},
                {keyframes.gatherBush3, 0.1, {randomVariance = 0.3}},
                {keyframes.gatherBush1, 0.5, {randomVariance = 0.6}},
                {keyframes.gatherBush3, 0.3, {randomVariance = 0.2}},
                {keyframes.gatherBush2, 0.5, {randomVariance = 0.8}},
                {keyframes.gatherBush4, 0.3, {randomVariance = 0.3}},
                {keyframes.gatherBush4, 0.4, {randomVariance = 0.8}},
                {keyframes.gatherBush2, 0.2, {randomVariance = 0.1}},
                {keyframes.gatherBush2, 0.3, {randomVariance = 0.4}},
           },
       },
        takeOffTorsoClothing = {
            keyframes = {
                {keyframes.reachUp1, 0.2},
                {keyframes.reachUp2, 0.5, {randomVariance = 0.1}},
           },
       },
        putOnTorsoClothing = {
            keyframes = {
                {keyframes.reachUp1, 0.2},
                {keyframes.reachUp2, 0.5, {randomVariance = 0.1}},
           },
       },
        chop = {
            keyframes = {
                {keyframes.chop1, 0.8, {randomVariance = 0.1}},
                {keyframes.chop2, 0.3, {randomVariance = 0.1}},
                {keyframes.chop3, 0.1, {randomVariance = 0.01}},
                {keyframes.chop3, 0.4, {randomVariance = 0.01, trigger = chopTrigger}},
                {keyframes.chop4, 0.5, {randomVariance = 0.1}},
           },
       },
        mine = {
            keyframes = {
                {keyframes.chop1, 0.8, {randomVariance = 0.1}},
                {keyframes.chop2, 0.3, {randomVariance = 0.1}},
                {keyframes.chop3, 0.1, {randomVariance = 0.01, trigger = mineTrigger}},
                {keyframes.chop3, 0.4, {randomVariance = 0.05}},
                {keyframes.chop4, 0.5, {randomVariance = 0.1}},
           },
       },
        pullWeeds = {
            keyframes = {
                {keyframes.pullWeeds1, 0.2, {randomVariance = 0.05}},
                {keyframes.pullWeeds2, 0.3, {randomVariance = 0.05}},
                {keyframes.pullWeeds3, 0.4, {randomVariance = 0.05}},
                {keyframes.pullWeeds3, 0.2, {randomVariance = 0.05}},
                {keyframes.pullWeeds4, 0.2, {randomVariance = 0.05, trigger = pullWeedsTrigger}},
                {keyframes.pullWeeds4, 0.5, {randomVariance = 0.05}},
                {keyframes.pullWeeds2, 0.4, {randomVariance = 0.05}},
                {keyframes.pullWeeds1, 0.3, {randomVariance = 0.5}}, 
           },
       },
        eat = {
            keyframes = {
                {keyframes.eat1, 0.2},
                {keyframes.eat2, 0.3, {trigger = eatTrigger}},
                {keyframes.eat3, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat3, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat3, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat3, 0.2},
                {keyframes.eat4, 0.2},
                {keyframes.eat4, 0.2},
           },
       },
        playFlute = {
            proceduralType = 1,
            keyframes = {
                {keyframes.playFlute1, 0.3, {randomVariance = 0.1}},
                {keyframes.playFlute2, 0.5, {randomVariance = 0.1}},
                {keyframes.playFlute1, 0.4, {randomVariance = 4.1}},
                {keyframes.playFlute2, 0.4, {randomVariance = 0.1}},
                {keyframes.playFlute1, 0.5, {randomVariance = 3.1}},
           },
       },
        playDrum = {
            keyframes = {
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum3, drumPlaySpeedSlow},
                {keyframes.playDrum3, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum3, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum3, drumPlaySpeedSlow},
                {keyframes.playDrum3, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum3, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
           },
       },
        playBalafon = {
            keyframes = {
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedSlow},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
                {keyframes.playDrum1, drumPlaySpeedFast, {composites = {leftHitDrum, rightHitDrum}}},
           },
       },
        wave = {
            keyframes = {
                {keyframes.wave3, 0.2},
           },
       },
        sleep = {
            keyframes = {
                {keyframes.sleep, 0.2},
           },
       },
        light = {
            keyframes = {
                {keyframes.light1, 0.3, {randomVariance = 0.03}},
                {keyframes.light2, 0.3, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.knapLook, 0.5, {randomVariance = 0.5}},
                {keyframes.knapLook, 0.5, {randomVariance = 2.5}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.15, {randomVariance = 0.03}},
                {keyframes.light2, 0.15, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light1, 0.2, {randomVariance = 0.03}},
                {keyframes.light2, 0.2, {randomVariance = 0.1, trigger = scrapeTrigger}},
                {keyframes.light3, 0.3, {randomVariance = 0.03}},
                {keyframes.light3, 0.5, {randomVariance = 1.5}},
           },
       },
        kick = {
            keyframes = {
                {keyframes.stand, 0.5},
                {keyframes.kick1, 0.3},
                {keyframes.kick2, 0.3, {trigger = kickTrigger}},
                {keyframes.stand, 0.5},
           },
       },
        swim = {
            keyframes = {
                {keyframes.swim1, 0.1},
                {keyframes.swim2, 0.15},
                {keyframes.swim3, 0.05},
                {keyframes.swim4, 0.1},
                {keyframes.swim5, 0.05},
           },
       },
        swimCarry = {
            keyframes = {
                {keyframes.swim1, 0.1, {composites = {standardCarryComposite}}},
                {keyframes.swim2, 0.15, {composites = {standardCarryComposite}}},
                {keyframes.swim3, 0.05, {composites = {standardCarryComposite}}},
                {keyframes.swim4, 0.1, {composites = {standardCarryComposite}}},
                {keyframes.swim5, 0.05, {composites = {standardCarryComposite}}},
           },
       },
        swimHighCarry = {
            keyframes = {
                {keyframes.swim1, 0.1, {composites = {highCarryComposite}}},
                {keyframes.swim2, 0.15, {composites = {highCarryComposite}}},
                {keyframes.swim3, 0.05, {composites = {highCarryComposite}}},
                {keyframes.swim4, 0.1, {composites = {highCarryComposite}}},
                {keyframes.swim5, 0.05, {composites = {highCarryComposite}}},
           },
       },
        swimHighSmallCarry = {
            keyframes = {
                {keyframes.swim1, 0.1, {composites = {highSmallCarryComposite}}},
                {keyframes.swim2, 0.15, {composites = {highSmallCarryComposite}}},
                {keyframes.swim3, 0.05, {composites = {highSmallCarryComposite}}},
                {keyframes.swim4, 0.1, {composites = {highSmallCarryComposite}}},
                {keyframes.swim5, 0.05, {composites = {highSmallCarryComposite}}},
           },
       },
        swimHighMediumCarry = {
            keyframes = {
                {keyframes.swim1, 0.1, {composites = {highMediumCarryComposite}}},
                {keyframes.swim2, 0.15, {composites = {highMediumCarryComposite}}},
                {keyframes.swim3, 0.05, {composites = {highMediumCarryComposite}}},
                {keyframes.swim4, 0.1, {composites = {highMediumCarryComposite}}},
                {keyframes.swim5, 0.05, {composites = {highMediumCarryComposite}}},
           },
       },
        swimSmallCarry = {
            keyframes = {
                {keyframes.swim1, 0.1, {composites = {smallCarryComposite}}},
                {keyframes.swim2, 0.15, {composites = {smallCarryComposite}}},
                {keyframes.swim3, 0.05, {composites = {smallCarryComposite}}},
                {keyframes.swim4, 0.1, {composites = {smallCarryComposite}}},
                {keyframes.swim5, 0.05, {composites = {smallCarryComposite}}},
           },
       },

        treadWater = {
            keyframes = {
                {keyframes.treadWater1, 0.2},
                {keyframes.treadWater2, 0.2},
           },
       },
        treadWaterCarry = {
            keyframes = {
                {keyframes.treadWater1, 0.2, {composites = {standardCarryComposite}}},
                {keyframes.treadWater2, 0.2, {composites = {standardCarryComposite}}},
           },
       },
        treadWaterHighCarry = {
            keyframes = {
                {keyframes.treadWater1, 0.2, {composites = {highCarryComposite}}},
                {keyframes.treadWater2, 0.2, {composites = {highCarryComposite}}},
           },
       },
        treadWaterHighSmallCarry = {
            keyframes = {
                {keyframes.treadWater1, 0.2, {composites = {highSmallCarryComposite}}},
                {keyframes.treadWater2, 0.2, {composites = {highSmallCarryComposite}}},
           },
       },
        treadWaterHighMediumCarry = {
            keyframes = {
                {keyframes.treadWater1, 0.2, {composites = {highMediumCarryComposite}}},
                {keyframes.treadWater2, 0.2, {composites = {highMediumCarryComposite}}},
           },
       },
        treadWaterSmallCarry = {
            keyframes = {
                {keyframes.treadWater1, 0.2, {composites = {smallCarryComposite}}},
                {keyframes.treadWater2, 0.2, {composites = {smallCarryComposite}}},
           },
       },


        throwAim = {
            keyframes = {
                {keyframes.throwAim, 0.2},
           },
       },
        throw = {
            keyframes = {
                {keyframes.throw1, 0.05},
                {keyframes.throw2, 0.05},
                {keyframes.throw3, 0.2},
                {keyframes.throw3, 0.2},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
                {keyframes.stand, 0.4},
           },
       },
        highCarry = {
            keyframes = {
                {keyframes.highCarry, 0.2},
           },
       },
        pickupHighCarry = {
            keyframes = {
                {keyframes.pickupHighCarry, 0.4},
           },
       },
        addToHighCarry = {
            keyframes = {
                {keyframes.addToHighCarry, 0.2},
           },
       },
        placeCrouchHighCarry = {
            keyframes = {
                {keyframes.addToHighCarry, 0.4},
           },
       },
        removeFromHighCarry = {
            keyframes = {
                {keyframes.pickupHighCarry, 0.2},
           },
       },
        highSmallCarry = {
            keyframes = {
                {keyframes.highSmallCarry, 0.2},
           },
       },
        pickupHighSmallCarry = {
            keyframes = {
                {keyframes.pickupHighSmallCarry, 0.4},
           },
       },
        addToHighSmallCarry = {
            keyframes = {
                {keyframes.addToHighSmallCarry, 0.2},
           },
       },
        placeCrouchHighSmallCarry = {
            keyframes = {
                {keyframes.addToHighSmallCarry, 0.4},
           },
       },
        removeFromHighSmallCarry = {
            keyframes = {
                {keyframes.pickupHighSmallCarry, 0.2},
           },
       },
        highMediumCarry = {
            keyframes = {
                {keyframes.highMediumCarry, 0.2},
           },
       },
        pickupHighMediumCarry = {
            keyframes = {
                {keyframes.pickupHighMediumCarry, 0.4},
           },
       },
        addToHighMediumCarry = {
            keyframes = {
                {keyframes.addToHighMediumCarry, 0.2},
           },
       },
        placeCrouchHighMediumCarry = {
            keyframes = {
                {keyframes.addToHighMediumCarry, 0.4},
           },
       },
        removeFromHighMediumCarry = {
            keyframes = {
                {keyframes.pickupHighMediumCarry, 0.2},
           },
       },
        smallCarry = {
            keyframes = {
                {keyframes.smallCarry, 0.2},
           },
       },
        pickupSmallCarry = {
            keyframes = {
                {keyframes.pickupSmallCarry, 0.4},
           },
       },
        addToSmallCarry = {
            keyframes = {
                {keyframes.addToSmallCarry, 0.2},
           },
       },
        placeCrouchSmallCarry = {
            keyframes = {
                {keyframes.addToSmallCarry, 0.4},
           },
       },
        removeFromSmallCarry = {
            keyframes = {
                {keyframes.pickupSmallCarry, 0.2},
           },
       },
        crouchSmallCarrySingle = {
            keyframes = {
                {keyframes.crouchSmallCarry, 0.2},
           },
       },
        crouchSmallCarryMulti = {
            keyframes = {
                {keyframes.addToSmallCarry, 0.2},
           },
       },
        crouchHighCarry = {
            keyframes = {
                {keyframes.addToHighCarry, 0.2},
           },
       },
        crouchHighSmallCarry = {
            keyframes = {
                {keyframes.addToHighSmallCarry, 0.2},
           },
       },
        crouchHighMediumCarry = {
            keyframes = {
                {keyframes.addToHighMediumCarry, 0.2},
           },
       },
        crouchSingleCarry = {
            keyframes = {
                {keyframes.pickup, 0.2},
           },
       },
        knap = {
            keyframes = {
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.3, {randomVariance = 0.1}},
                {keyframes.knap2, 1.2, {randomVariance = 0.5}},
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.2, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.3, {randomVariance = 0.1}},
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.4, {randomVariance = 0.1}},
                {keyframes.knapLook, 0.3, {randomVariance = 0.5}},
                {keyframes.knapLook, 1.8, {randomVariance = 2.5}},
                {keyframes.knap2, 0.8, {randomVariance = 0.1}},
                {keyframes.knap2, 1.4, {randomVariance = 0.5}},
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.3, {randomVariance = 0.1}},
                {keyframes.knap2, 0.4, {randomVariance = 0.5}},
                {keyframes.knap2, 2.0, {randomVariance = 0.5}},
                {keyframes.knapLook, 0.3, {randomVariance = 0.3}},
                {keyframes.knapLook, 0.8, {randomVariance = 4.5}},
                {keyframes.knap2, 0.4, {randomVariance = 0.5}},
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.2, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.3, {randomVariance = 0.1}},
                {keyframes.knap3, 0.2, {randomVariance = 0.1}},
                {keyframes.knap1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knap2, 0.4, {randomVariance = 0.1}},
                {keyframes.light3, 0.2, {randomVariance = 0.5}},
                {keyframes.light3, 0.8, {randomVariance = 4.5}},
           },
       },
        knapCrude = {
            keyframes = {
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.3, {randomVariance = 0.1}},
                {keyframes.knapCrude2, 1.2, {randomVariance = 4.5}},
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.2, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.3, {randomVariance = 0.1}},
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.4, {randomVariance = 0.1}},
                {keyframes.knapCrude2, 0.8, {randomVariance = 0.1}},
                {keyframes.knapCrude2, 1.4, {randomVariance = 4.5}},
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.3, {randomVariance = 0.1}},
                {keyframes.knapCrude2, 0.4, {randomVariance = 0.5}},
                {keyframes.knapCrude2, 2.0, {randomVariance = 4.5}},
                {keyframes.knapCrude2, 0.4, {randomVariance = 0.5}},
                {keyframes.knapCrude2, 1.2, {randomVariance = 0.5}},
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.2, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.3, {randomVariance = 0.1}},
                {keyframes.knapCrude3, 0.2, {randomVariance = 0.1}},
                {keyframes.knapCrude1, 0.3, {randomVariance = 0.01, trigger = knapTrigger}},
                {keyframes.knapCrude2, 0.4, {randomVariance = 0.1}},
           },
       },
        grind = {
            keyframes = {
                {keyframes.grind1, 0.3, {randomVariance = 0.01}},
                {keyframes.grind2, 0.3, {randomVariance = 0.01, trigger = grindTrigger}},
                {keyframes.grind3, 0.3, {randomVariance = 0.1}},
                {keyframes.grind4, 0.3, {randomVariance = 0.1}},
                {keyframes.grind1, 0.3, {randomVariance = 0.01}},
                {keyframes.grind2, 0.3, {randomVariance = 0.01}},
                {keyframes.grind3, 0.3, {randomVariance = 0.1}},
                {keyframes.grind4, 0.3, {randomVariance = 0.1}},
                {keyframes.grind4, 0.3, {randomVariance = 0.1}},
           },
       },
        applyMedicine = {
            keyframes = {
                {keyframes.medicine1, 0.3, {randomVariance = 0.01}},
                {keyframes.medicine2, 0.3, {randomVariance = 0.01}},
                {keyframes.medicine3, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine4, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine5, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine1, 0.3, {randomVariance = 0.01}},
                {keyframes.medicine2, 0.3, {randomVariance = 0.01}},
                {keyframes.medicine3, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine4, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine5, 0.3, {randomVariance = 0.1}},
                {keyframes.medicine5, 0.3, {randomVariance = 0.1}},
           },
       },
        scrapeWood = {
            keyframes = {
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrapeLook1, 0.4, {randomVariance = 0.1}},
                {keyframes.scrapeLook1, 1.8, {randomVariance = 0.1}},
                {keyframes.scrapeLook2, 0.4, {randomVariance = 0.1}},
                {keyframes.scrapeLook2, 1.8, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.8, {randomVariance = 0.1}},
                {keyframes.scrape1, 1.4, {randomVariance = 0.1}},
           },
       },
        butcher = {
            keyframes = {
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape2, 0.1, {randomVariance = 0.01, trigger = scrapeTrigger}},
                {keyframes.scrape2, 0.2, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.1, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.2, {randomVariance = 0.1}},
                {keyframes.scrapeLook1, 0.4, {randomVariance = 0.1}},
                {keyframes.scrapeLook1, 1.8, {randomVariance = 0.1}},
                {keyframes.scrapeLook2, 0.4, {randomVariance = 0.1}},
                {keyframes.scrapeLook2, 1.8, {randomVariance = 0.1}},
                {keyframes.scrape1, 0.8, {randomVariance = 0.1}},
                {keyframes.scrape1, 1.4, {randomVariance = 0.1}},
           },
       },
        fireStickCook = {
            proceduralType = 1,
            keyframes = {
                {keyframes.fireStickCook1, 0.2, {randomVariance = 0.1}},
                {keyframes.fireStickCook1, 1.5, {randomVariance = 0.3}},
                {keyframes.fireStickCook2, 0.2, {randomVariance = 0.1}},
                {keyframes.fireStickCook2, 0.8, {randomVariance = 0.2}},
                {keyframes.fireStickCook1, 0.2, {randomVariance = 0.1}},
                {keyframes.fireStickCook1, 2.0, {randomVariance = 0.4}},
                {keyframes.fireStickCook3, 0.2, {randomVariance = 0.1}},
                {keyframes.fireStickCook3, 3.5, {randomVariance = 0.1}},
           },
       },
        patDown = {
            proceduralType = 1,
            keyframes = {
                {keyframes.patDown1, 0.5, {randomVariance = 0.1}},
                {keyframes.patDown2, 0.5, {randomVariance = 0.1}},
                {keyframes.patDown3, 0.2, {randomVariance = 0.1}},
                {keyframes.patDown1, 0.5, {randomVariance = 0.1}},
                {keyframes.patDown3, 0.2, {randomVariance = 0.1}},
                {keyframes.patDown2, 0.5, {randomVariance = 0.1}},
           },
       },
        standInspect = {
            proceduralType = 1,
            keyframes = {
                {keyframes.inspect3, 0.8, {randomVariance = 1.0}},
                {keyframes.inspect3, 3.2, {randomVariance = 1.0}},
                {keyframes.inspect3, 0.8, {randomVariance = 1.0}},
                {keyframes.inspect1, 0.8, {randomVariance = 1.0}},
                {keyframes.inspect1, 2.8, {randomVariance = 1.0}},
                {keyframes.inspect1, 0.8, {randomVariance = 1.0}},
                {keyframes.inspect2, 0.4, {randomVariance = 1.0}},
                {keyframes.inspect2, 2.5, {randomVariance = 1.0}},
                {keyframes.inspect2, 0.8, {randomVariance = 1.0}},
           },
       },

        sneakStand = {
            keyframes = {
                {keyframes.sneakStand, 0.2},
           },
       },
        sneakStandCarry = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {standardCarryComposite}}},
           },
       },
        sneakStandHighCarry = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {highCarryComposite}}},
           },
       },
        sneakStandHighSmallCarry = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {highSmallCarryComposite}}},
           },
       },
        sneakStandHighMediumCarry = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {highMediumCarryComposite}}},
           },
       },
        sneakStandSmallCarry = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {smallCarryComposite}}},
           },
       },
        sneakStandWave = {
            keyframes = {
                {keyframes.sneakStand, 0.2, {composites = {waveComposite}}},
           },
       },
        
        sitFocus = {
            keyframes = {
                {keyframes.sitFocus, 0.2},
           },
       },
        sit1 = {
            keyframes = {
                {keyframes.sit1, 0.2},
           },
       },
        sit2 = {
            keyframes = {
                {keyframes.sit2, 0.2},
           },
       },
        sit3 = {
            keyframes = {
                {keyframes.sit3, 0.2},
           },
       },
        sit4 = {
            keyframes = {
                {keyframes.sit4, 0.2},
           },
       },
        sitLowSeat1 = {
            keyframes = {
                {keyframes.sitLowSeat1, 0.2},
           },
       },
        
        sitFocusWave = {
            keyframes = {
                {keyframes.sitFocus, 0.2, {composites = {waveComposite}}},
           },
       },
        sit1Wave = {
            keyframes = {
                {keyframes.sit1, 0.2, {composites = {waveComposite}}},
           },
       },
        sit2Wave = {
            keyframes = {
                {keyframes.sit2, 0.2, {composites = {waveComposite}}},
           },
       },
        sit3Wave = {
            keyframes = {
                {keyframes.sit3, 0.2, {composites = {waveComposite}}},
           },
       },
        sit4Wave = {
            keyframes = {
                {keyframes.sit4, 0.2, {composites = {waveComposite}}},
           },
       },
        sitLowSeat1Wave = {
            keyframes = {
                {keyframes.sitLowSeat1, 0.2, {composites = {waveComposite}}},
           },
       },

        crouchDig = {
            keyframes = {
                {keyframes.crouchDig1, 0.8, {randomVariance = 0.1}},
                {keyframes.crouchDig2, 0.3, {randomVariance = 0.1}},
                {keyframes.crouchDig3, 0.6, {randomVariance = 0.1}},
                {keyframes.crouchDig4, 0.1, {randomVariance = 0.05, trigger = digTrigger}},
           },
       },

        pottery = {
            proceduralType = 1,
            keyframes = {
                {keyframes.pottery1, 0.3, {randomVariance = 0.1}},
                {keyframes.pottery3, 1.2, {randomVariance = 0.1}},
                {keyframes.pottery3, 0.2, {randomVariance = 0.1}},
                {keyframes.pottery2, 0.3, {randomVariance = 0.1}},
                {keyframes.pottery2, 0.3, {randomVariance = 0.2}},
                {keyframes.pottery1, 0.2, {randomVariance = 0.1}},
                {keyframes.pottery2, 0.4, {randomVariance = 0.2}},
                {keyframes.pottery3, 4.5, {randomVariance = 0.1}},
                {keyframes.pottery4, 0.2, {randomVariance = 0.1}},
           },
       },

        
        toolAssembly = {
            proceduralType = 1,
            keyframes = {
                {keyframes.pottery3, 0.3, {randomVariance = 0.8}},
                {keyframes.scrape1, 0.3, {randomVariance = 0.8}},
                {keyframes.scrape2, 0.3, {randomVariance = 0.8}},
                {keyframes.scrapeLook1, 0.4, {randomVariance = 0.8}},
                {keyframes.scrapeLook1, 1.0, {randomVariance = 0.8}},
                {keyframes.knapCrude2, 1.0, {randomVariance = 0.5}},
               -- {keyframes.knapCrude3, 0.3, {randomVariance = 0.8}},
                {keyframes.knap2, 1.2, {randomVariance = 0.5}},
              --  {keyframes.knap3, 0.3, {randomVariance = 0.8}},
                --{keyframes.sitFocus, 0.3, {randomVariance = 0.8}},
           },
       },

        thresh = {
            keyframes = {
                {keyframes.thresh1, 0.8, {randomVariance = 0.1}},
                {keyframes.thresh2, 0.1, {randomVariance = 0.01}},
                {keyframes.thresh3, 0.05, {randomVariance = 0.05, trigger = threshTrigger}},
                {keyframes.thresh3, 0.2, {randomVariance = 0.1}},
                {keyframes.thresh4, 0.8, {randomVariance = 0.1}},
           },
       },

        fall = {
            keyframes = {
                {keyframes.fall1, 0.3, {randomVariance = 0.1}},
                {keyframes.fall2, 0.3, {randomVariance = 0.1}},
                {keyframes.fall3, 0.3, {randomVariance = 0.1}},
                {keyframes.fall4, 0.3, {randomVariance = 0.1}},
                {keyframes.fall5, 0.2, {randomVariance = 0.1}},
                {keyframes.fall6, 0.3, {randomVariance = 0.1}},
                {keyframes.fall7, 0.2, {randomVariance = 0.1}},
                {keyframes.fall8, 0.3, {randomVariance = 0.1}},
                {keyframes.fall8, 2.0 },
                {keyframes.fall8, 2.0 },
                {keyframes.fall8, 2.0 },
                {keyframes.fall8, 2.0 },
                {keyframes.fall8, 2.0 },
                {keyframes.fall8, 2.0 },
           },
       },

        smithHammer = {
            keyframes = {
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.3, {randomVariance = 0.1}},
                {keyframes.smithHammer2, 1.2, {randomVariance = 0.5}},
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.3, {randomVariance = 0.1}},
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.4, {randomVariance = 0.1}},
                {keyframes.smithLook, 0.3, {randomVariance = 0.5}},
                {keyframes.smithLook, 1.8, {randomVariance = 2.5}},
                {keyframes.smithHammer2, 0.8, {randomVariance = 0.1}},
                {keyframes.smithHammer2, 1.4, {randomVariance = 0.5}},
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.3, {randomVariance = 0.1}},
                {keyframes.smithHammer2, 0.4, {randomVariance = 0.5}},
                {keyframes.smithHammer2, 2.0, {randomVariance = 0.5}},
                {keyframes.smithLook, 0.3, {randomVariance = 0.3}},
                {keyframes.smithLook, 0.8, {randomVariance = 4.5}},
                {keyframes.smithHammer2, 0.4, {randomVariance = 0.5}},
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.3, {randomVariance = 0.1}},
                {keyframes.smithHammer3, 0.2, {randomVariance = 0.1}},
                {keyframes.smithHammer1, 0.1, {randomVariance = 0.01, trigger = smithHammerTrigger}},
                {keyframes.smithHammer2, 0.4, {randomVariance = 0.1}},
                {keyframes.smithLook, 0.2, {randomVariance = 0.5}},
                {keyframes.smithLook, 0.8, {randomVariance = 4.5}},
           },
       },
        

        chisel = {
            keyframes = {
                {keyframes.chisel1, 0.5, {randomVariance = 0.3}},
                {keyframes.chisel2, 0.2, {randomVariance = 0.1}},
                {keyframes.chisel3, 0.1, {randomVariance = 0.05}},
                {keyframes.chisel4, 0.1, {randomVariance = 0.05, trigger = chiselTrigger}},
           },
       },

        row = {
            keyframes = {
                {keyframes.row1, 0.4, {randomVariance = 0.1}},
                {keyframes.row2, 0.4, {randomVariance = 0.1, trigger = rowTrigger}},
                {keyframes.row3, 0.4, {randomVariance = 0.1}},
                {keyframes.row4, 0.4, {randomVariance = 0.1}},
           },
       },
   }

    local function addWalkRunCycle(baseName, keyframeBaseName, frameDuration, stepTriggerToUse, durationMultipliersOrNil, additionalCompositeOrNil)

        local keyframeNames = {}
        local durations = {}
        for i=1,8 do
            keyframeNames[i] = keyframeBaseName .. mj:tostring(i)
            durations[i] = frameDuration
            if durationMultipliersOrNil then
                durations[i] = frameDuration * durationMultipliersOrNil[i]
            end
        end

        local standardComposites = nil
        local standardCarryComposites = {standardCarryComposite}
        local highCarryComposites = {highCarryComposite}
        local highSmallCarryComposites = {highSmallCarryComposite}
        local highMediumCarryComposites = {highMediumCarryComposite}
        local smallCarryComposites = {smallCarryComposite}
        local waveComposites = {waveComposite}

        if additionalCompositeOrNil then
            standardComposites = {additionalCompositeOrNil}
            table.insert(standardCarryComposites, additionalCompositeOrNil)
            table.insert(highCarryComposites, additionalCompositeOrNil)
            table.insert(highSmallCarryComposites, additionalCompositeOrNil)
            table.insert(highMediumCarryComposites, additionalCompositeOrNil)
            table.insert(smallCarryComposites, additionalCompositeOrNil)
            table.insert(waveComposites, additionalCompositeOrNil)
        end


        mj:insertIndexed(animationInfo.animations, {
            key = baseName,
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = standardComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = standardComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = standardComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = standardComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = standardComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = standardComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = standardComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = standardComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "Carry",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = standardCarryComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = standardCarryComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = standardCarryComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "HighCarry",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = highCarryComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = highCarryComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = highCarryComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = highCarryComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = highCarryComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = highCarryComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = highCarryComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = highCarryComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "HighSmallCarry",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = highSmallCarryComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = highSmallCarryComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = highSmallCarryComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "HighMediumCarry",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = highMediumCarryComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = highMediumCarryComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = highMediumCarryComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "SmallCarry",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = smallCarryComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = smallCarryComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = smallCarryComposites, trigger = stepTriggerToUse}},
            },
        })

        mj:insertIndexed(animationInfo.animations, {
            key = baseName .. "Wave",
            keyframes = {
                {keyframes[keyframeNames[1]], durations[1], {composites = waveComposites}},
                {keyframes[keyframeNames[2]], durations[2], {composites = waveComposites}},
                {keyframes[keyframeNames[3]], durations[3], {composites = waveComposites}},
                {keyframes[keyframeNames[4]], durations[4], {composites = waveComposites, trigger = stepTriggerToUse}},
                {keyframes[keyframeNames[5]], durations[5], {composites = waveComposites}},
                {keyframes[keyframeNames[6]], durations[6], {composites = waveComposites}},
                {keyframes[keyframeNames[7]], durations[7], {composites = waveComposites}},
                {keyframes[keyframeNames[8]], durations[8], {composites = waveComposites, trigger = stepTriggerToUse}},
            },
        })
    end

    addWalkRunCycle("walk", "walk", walkFrameDuration * walkDurationMultipier, stepTrigger, {0.8, 1.2, 0.8, 0.8, 0.8, 1.2, 0.8, 0.8})
    addWalkRunCycle("sneak", "sneak", sneakFrameDuration * walkDurationMultipier, nil, {1.0, 1.3, 1.0, 0.7, 1.0, 1.3, 1.0, 0.7})
    addWalkRunCycle("jog", "jog", jogFrameDuration * walkDurationMultipier, stepTrigger, {0.7, 1.0, 1.3, 1.0, 0.7, 1.0, 1.3, 1.0})
    addWalkRunCycle("run", "jog", runFrameDuration * walkDurationMultipier, stepTrigger, {0.7, 1.0, 1.3, 1.0, 0.7, 1.0, 1.3, 1.0})
    addWalkRunCycle("slowWalk", "slowWalk", slowWalkFrameDuration * walkDurationMultipier, stepTrigger, {0.8, 1.2, 0.8, 0.8, 0.8, 1.2, 0.8, 0.8})
    addWalkRunCycle("sadWalk", "sadWalk", sadWalkFrameDuration * walkDurationMultipier, stepTrigger, nil, grumpyComposite)

    addWalkRunCycle("dragObjectWalk", "dragObjectWalk", dragObjectWalkFrameDuration * walkDurationMultipier, stepTrigger, {0.8, 1.2, 0.8, 0.8, 0.8, 1.2, 0.8, 0.8})


    animationInfo.limits = {--Designed exclusively for head movement, if limits are set like this, currently roll is not supported, any z rotation will be discarded, with optionally a random roll generated and added.
        {
            boneName = "head",
            pitch = {
                min = -0.7, --up
                max = 0.5, --down
           },
            yaw = {
                min = -1.1,
                max = 1.1,
           },
            rate = 8.0,
            randomRoll = 0.2,
       }
   }
    

end

function sapienCommon:initMainThread()
    mainThreadParticleManagerInterface = mjrequire "mainThread/mainThreadParticleManagerInterface"
    audio = mjrequire "mainThread/audio"
end

return sapienCommon