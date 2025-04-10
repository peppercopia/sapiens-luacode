local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local tool = mjrequire "common/tool"
--local plan = mjrequire "common/plan"
--local skill = mjrequire "common/skill"
local locale = mjrequire "common/locale"

local mobChicken = {}

function mobChicken:load(mob, gameObject)
    mob:addType("chicken", {
        
        deadObjectTypeIndex = gameObject.typeIndexMap.deadChicken,

        initialHealth = 0.4,
        spawnFrequency = 0.6,
        spawnDistance = mj:mToP(200.0),
        minSapienProximityDistanceForSpawning = mj:mToP(1.0),
        
        reactDistance = mj:mToP(25.0),
        agroDistance = mj:mToP(1.0),
        runDistance = mj:mToP(15.0),

        agroTimerDuration = 3.0,
        aggresionLevel = nil,

        pathFindingRayRadius = mj:mToP(0.2),
        pathFindingRayYOffset = mj:mToP(0.2),
        walkSpeed = mj:mToP(0.3),
        runSpeedMultiplier = 8.0,
        rotationSpeedMultiplier = 2.0,
        embedBoxHalfSize = vec3(0.1,0.1,0.1),
        
        infrequentUpdatePeriod = 5.0, --default of 5.0, but mobs that move quickly need to be updated more frequently. Must be called every 4.5 meters of movement to avoid pauses.
        
        maxSoundDistance2 = mj:mToP(100.0) * mj:mToP(100.0),
        soundVolume = 0.4,
        soundRandomBaseName = "chicken",
        soundRandomBaseCount = 4,
        soundAngryBaseName = "chickenAngry",
        soundAngryBaseCount = 1,
        deathSound = "chickenDie",
        
        maxHunterAssignCount = 2,
        isSimpleSmallRockHuntType = true,
        
        animationGroup = "chicken",
        idleAnimations = {
            --"lookRight",
            "scratch2",
        },

        sleepAnimations = {
            "scratch2",
            --"sit",
        },
        
        runAnimation = "run",
        deathAnimation = "die",
        
        addGameObjectInfo = {
            name = locale:get("mob_chicken"),
            plural = locale:get("mob_chicken_plural"),
            modelName = "chicken",
            mobTypeIndex = mob.typeIndexMap.chicken,
            projectileAimHeightOffsetMeters = 0.2,
            scale = 1.0,
            hasPhysics = false,
			ignoreBuildRay = true,
            markerPositions = {
                { 
                    worldOffset = vec3(0.0, mj:mToP(0.8), 0.0)
                }
            },
        },
    })
end

return mobChicken

