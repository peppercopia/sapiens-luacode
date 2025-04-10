local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local tool = mjrequire "common/tool"
--local plan = mjrequire "common/plan"
--local skill = mjrequire "common/skill"
local locale = mjrequire "common/locale"

local mobSwordfish = {}

function mobSwordfish:load(mob, gameObject)
    mob:addType("swordfish", {
        
        deadObjectTypeIndex = gameObject.typeIndexMap.swordfishDead,
        swims = true,
        disallowedBiomeTags = {
            "river",
        },

        initialHealth = 1.9,
        spawnFrequency = 0.4,
        spawnDistance = mj:mToP(200.0),
        minSapienProximityDistanceForSpawning = mj:mToP(100.0),

        reactDistance = mj:mToP(50.0),
        agroDistance = mj:mToP(8.0),
        runDistance = mj:mToP(15.0),
        attackDistance = mj:mToP(2.0), --the existence of this is also used to determine if mob is hostile
        
        agroTimerDuration = 3.0,
        aggresionLevel = 1, -- nil or 0 will always run away from moderately close sapiens. 1 will hold ground sometimes, and also charge at the sapien when agro.
        

        pathFindingRayRadius = mj:mToP(0.6),
        pathFindingRayYOffset = mj:mToP(1.0),
        walkSpeed = mj:mToP(1.4),
        runSpeedMultiplier = 2.5,
        rotationSpeedMultiplier = 0.5,
        embedBoxHalfSize = vec3(0.3,0.2,0.5),
        
        infrequentUpdatePeriod = 2.0, --default of 5.0, but mobs that move quickly need to be updated more frequently. Must be called every 4.5 meters of movement to avoid pauses.

        maxHunterAssignCount = 5,
        
        animationGroup = "swordfish",
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

        agroWalkAnimation = "fastSwim",
        
        addGameObjectInfo = {
            name = locale:get("mob_swordfish"),
            plural = locale:get("mob_swordfish_plural"),
            modelName = "swordfish",
            mobTypeIndex = mob.typeIndexMap.swordfish,
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

return mobSwordfish

