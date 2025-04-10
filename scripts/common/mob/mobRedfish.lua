local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local tool = mjrequire "common/tool"
--local plan = mjrequire "common/plan"
--local skill = mjrequire "common/skill"
local locale = mjrequire "common/locale"

local mobRedfish = {}

function mobRedfish:load(mob, gameObject)
    mob:addType("redfish", {
        
        deadObjectTypeIndex = gameObject.typeIndexMap.redfishDead,
        swims = true,

        initialHealth = 0.9,
        spawnFrequency = 0.6,
        spawnDistance = mj:mToP(200.0),
        minSapienProximityDistanceForSpawning = mj:mToP(1.0),

        reactDistance = mj:mToP(10.0),
        agroDistance = mj:mToP(5.0),
        runDistance = mj:mToP(2.0),
        
        agroTimerDuration = 5.0,
        aggresionLevel = nil,

        pathFindingRayRadius = mj:mToP(0.6),
        pathFindingRayYOffset = mj:mToP(1.0),
        walkSpeed = mj:mToP(0.5),
        runSpeedMultiplier = 4.0,
        rotationSpeedMultiplier = 0.2,
        embedBoxHalfSize = vec3(0.3,0.2,0.5),
        
        infrequentUpdatePeriod = 2.0, --default of 5.0, but mobs that move quickly need to be updated more frequently. Must be called every 4.5 meters of movement to avoid pauses.
        

        maxHunterAssignCount = 5,
        
        animationGroup = "redfish",
        idleAnimations = {
            "slowSwim",
            "fastSwim",
        },
        
        agroIdleAnimations = {
            "fastSwim",
        },

        sleepAnimations = {
            "slowSwim",
        },
        
        runAnimation = "fastSwim",
        deathAnimation = "fastSwim",
        walkAnimation = "fastSwim",
        
        addGameObjectInfo = {
            name = locale:get("mob_redfish"),
            plural = locale:get("mob_redfish_plural"),
            modelName = "redfish",
            mobTypeIndex = mob.typeIndexMap.redfish,
            projectileAimHeightOffsetMeters = 0.0,
            scale = 1.0,
            hasPhysics = false,
			ignoreBuildRay = true,
            markerPositions = {
                { 
                    worldOffset = vec3(0.0, mj:mToP(1.8), 0.0)
                }
            },
        },
    })
end

return mobRedfish

