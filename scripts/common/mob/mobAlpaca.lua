local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
--local tool = mjrequire "common/tool"
--local plan = mjrequire "common/plan"
--local skill = mjrequire "common/skill"
local locale = mjrequire "common/locale"

local mobAlpaca = {}

function mobAlpaca:load(mob, gameObject)
    mob:addType("alpaca", {
        
        deadObjectTypeIndex = gameObject.typeIndexMap.deadAlpaca,

        initialHealth = 3.9,
        spawnFrequency = 0.6,
        spawnDistance = mj:mToP(400.0),
        minSapienProximityDistanceForSpawning = mj:mToP(50.0),

        reactDistance = mj:mToP(50.0),
        agroDistance = mj:mToP(5.0),
        runDistance = mj:mToP(30.0),
        
        agroTimerDuration = 5.0,
        aggresionLevel = nil,

        pathFindingRayRadius = mj:mToP(0.6),
        pathFindingRayYOffset = mj:mToP(1.0),
        walkSpeed = mj:mToP(0.7),
        runSpeedMultiplier = 8.0,
        rotationSpeedMultiplier = 1.5,
        embedBoxHalfSize = vec3(0.3,0.2,0.5),
        
        infrequentUpdatePeriod = 4.0, --default of 5.0, but mobs that move quickly need to be updated more frequently. Must be called every 4.5 meters of movement to avoid pauses.
        
        maxSoundDistance2 = mj:mToP(200.0) * mj:mToP(200.0),
        soundVolume = 0.2,
        soundRandomBaseName = "alpaca",
        soundRandomBaseCount = 2,
        soundAngryBaseName = "alpacaAngry",
        soundAngryBaseCount = 1,
        deathSound = "alpacaAngry1",
        
        pooFrequencyDays = 4,
        pooQuantity = 1,

        maxHunterAssignCount = 5,
        
        animationGroup = "alpaca",
        idleAnimations = {
            "stand1",
            --"stand2",
            --"stand3",
            --"stand4",
        },

        agroIdleAnimations = {
            "stand1",
            --"stand2",
            --"stand3",
            --"stand4",
        },

        sleepAnimations = {
            "sit1",
            "sit2",
        },
        
        runAnimation = "gallop",
        deathAnimation = "die",

        variants = {
            {
                -- no postfix allows us to set settings for the default variant
                --[[disallowedBiomeTags = {
                    "temperatureWinterCold", "temperatureWinterVeryCold"
                },]]
            },
            {
                postfix = "_white",
                requiredBiomeTags = { -- requires one of any of
                    "temperatureWinterCold", "temperatureWinterVeryCold"
                },
            },
            {
                postfix = "_black",
            },
            {
                postfix = "_red",
                disallowedBiomeTags = {
                    "temperatureWinterCold", "temperatureWinterVeryCold"
                },
            },
            {
                postfix = "_yellow",
                requiredBiomeTags = { -- requires one of any of
                    "desert", "steppe"
                },
                disallowedBiomeTags = {
                    "temperatureWinterCold", "temperatureWinterVeryCold"
                },
            },
            {
                postfix = "_cream",
            },
        },
        variantAddOutputObjectVariants = {"alpacaWoolskin"}, --array of objectType keys
        variantAddRemapModels = {
            alpaca = {"alpaca", "alpaca_head"}, --array of material names to add postfix for remap eg. will add a remapModel name alpaca_white with the materials "alpaca" and "alpaca_head" remapped to "alpaca_white" and "alpaca_head_white"
            alpacaDead = {"alpaca", "alpaca_head"},
            alpacaWoolskin = {"alpacaWool", "alpacaWoolNoDecal"},

            woolskinBed_1 = {"clothes", "clothesNoDecal"},
            woolskinBed_2 = {"clothes", "clothesNoDecal"},
            woolskinBed_3 = {"clothes", "clothesNoDecal"},

            coveredSledEmptyWoolskin = {"clothes", "clothesNoDecal"},
            coveredSledHalfFullWoolskin = {"clothes", "clothesNoDecal"},
            coveredSledFullWoolskin = {"clothes", "clothesNoDecal"},

            coveredCanoeEmptyWoolskin = {"clothes", "clothesNoDecal"},
            coveredCanoeHalfFullWoolskin = {"clothes", "clothesNoDecal"},
            coveredCanoeFullWoolskin = {"clothes", "clothesNoDecal"},
        },
        variantAddModelPlaceholders = {
            woolskinBedRemaps_1 = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "woolskinBed_1"
            },
            woolskinBedRemaps_2 = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "woolskinBed_2"
            },
            woolskinBedRemaps_3 = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "woolskinBed_3"
            },

            
            coveredSledEmptyWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredSledEmptyWoolskin"
            },
            coveredSledHalfFullWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredSledHalfFullWoolskin"
            },
            coveredSledFullWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredSledFullWoolskin"
            },

            
            coveredCanoeEmptyWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredCanoeEmptyWoolskin"
            },
            coveredCanoeHalfFullWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredCanoeHalfFullWoolskin"
            },
            coveredCanoeFullWoolskinRemaps = {
                objectTypeKey = "alpacaWoolskin",
                modelKey = "coveredCanoeFullWoolskin"
            },
        },
        variantAddSapienClothingRemaps = {
            objectTypeKey = "alpacaWoolskin",
            materials = {
                clothes = "clothes", 
                clothingFur = "clothingFur", 
                clothingFurShort = "clothingFurShort", 
                cloak = "clothes", 
                cloakFur = "clothingFur",
                cloakFurShort = "clothingFurShort",
            },
        },
        
        --[[[gameObject.types.alpacaWoolskin_white.index] = {
            cloak = "clothes_white",
            cloakFur = "clothingFur_white",
            cloakFurShort = "clothingFurShort_white",
        }]]
        
        addGameObjectInfo = {
            name = locale:get("mob_alpaca"),
            plural = locale:get("mob_alpaca_plural"),
            modelName = "alpaca",
            mobTypeIndex = mob.typeIndexMap.alpaca,
            projectileAimHeightOffsetMeters = 1.5,
            scale = 1.0,
            hasPhysics = false,
			ignoreBuildRay = true,
            markerPositions = {
                { 
                    worldOffset = vec3(0.0, mj:mToP(1.8), 0.0)
                }
            }
        },
    })
end

return mobAlpaca

