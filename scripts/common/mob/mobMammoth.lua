local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local tool = mjrequire "common/tool"
--local plan = mjrequire "common/plan"
local notification = mjrequire "common/notification"
local locale = mjrequire "common/locale"

local mobMammoth = {}

function mobMammoth:load(mob, gameObject)
    mob:addType("mammoth", {

        deadObjectTypeIndex = gameObject.typeIndexMap.deadMammoth,
        killNotificationTypeIndex = notification.types.mammothKill.index,
        dontSpawnInEarlyGame = true,

        initialHealth = 19.9,
        spawnFrequency = 0.4,
        spawnDistance = mj:mToP(800.0), --heard will spawn approx this distance away from some sapien, then walk moderately close, pass by and despawn this same distance further on
        minSapienProximityDistanceForSpawning = mj:mToP(100.0),

        reactDistance = mj:mToP(50.0),
        runDistance = mj:mToP(15.0),
        agroDistance = mj:mToP(8.0),
        attackDistance = mj:mToP(2.0), --the existence of this is also used to determine if mob is hostile
        
        agroTimerDuration = 3.0,
        aggresionLevel = 1, -- nil or 0 will always run away from moderately close sapiens. 1 will hold ground sometimes, and also charge at the sapien when agro.

        pathFindingRayRadius = mj:mToP(2.0),
        pathFindingRayYOffset = mj:mToP(3.5),
        walkSpeed = mj:mToP(1.4),
        runSpeedMultiplier = 6.0,
        rotationSpeedMultiplier = 0.6,
        embedBoxHalfSize = vec3(1.0,1.0,2.5),

        pooFrequencyDays = 4,
        pooQuantity = 3,

        infrequentUpdatePeriod = 2.0, --default of 5.0, but mobs that move quickly need to be updated more frequently. Must be called every 4.5 meters of movement to avoid pauses.
        
        maxHunterAssignCount = 10,

        maxSoundDistance2 = mj:mToP(400.0) * mj:mToP(400.0),
        soundVolume = 2.0,
        soundRandomBaseName = "mammoth",
        soundRandomBaseCount = 6,
        soundAngryBaseName = "mammothAngry",
        soundAngryBaseCount = 3,
        deathSound = "mammothAngry1",
        
        animationGroup = "mammoth",
        idleAnimations = {
            "stand1",
            "stand2",
            "stand3",
            "stand4",
        },

        agroIdleAnimations = {
            "agro1",
        },

        sleepAnimations = {
            "sleep1",
        },

        agroWalkAnimation = "agroWalk",
        
        addGameObjectInfo = {
            name = locale:get("mob_mammoth"),
            plural = locale:get("mob_mammoth_plural"),
            modelName = "mammoth",
            mobTypeIndex = mob.typeIndexMap.mammoth,
            projectileAimHeightOffsetMeters = 3.0,
            scale = 1.0,
            hasPhysics = false,
			ignoreBuildRay = true,
            markerPositions = {
                { 
                    worldOffset = vec3(0.0, mj:mToP(5.8), 0.0)
                }
            },
        },
    })
end

return mobMammoth

