
local mjm = mjrequire "common/mjm"

local rng = mjrequire "common/randomNumberGenerator"
local sapienConstants = mjrequire "common/sapienConstants"
local sapienInventory = mjrequire "common/sapienInventory"

local gameObject = nil

local modelComposite = {}


modelComposite.basePath = "composite/sapien/"

local femaleIndex = 1
local maleIndex = 2

modelComposite.skinMaterials = {
    "skinDarkest",
    "skinDarker",
    "skinDark",
    "skin",
    "skinLight",
    "skinLighter",
    "skinLightest",
}

modelComposite.hairMaterials = {
	"hairDarkest",
	"hairDarker",
	"hair",
	"hairRed",
	"hairBlond",
}

modelComposite.hairNoDecalMaterials = {
	"hairDarkestNoDecal",
	"hairDarkerNoDecal",
	"hairNoDecal",
	"hairRedNoDecal",
	"hairBlondNoDecal",
}

modelComposite.eyebrowsMaterials = {
	"eyebrowsDarkest",
	"eyebrowsDarker",
	"eyebrows",
	"eyebrowsRed",
	"eyebrowsBlond",
}

modelComposite.eyeMaterials = {
	"eyeBallDarkBrown",
	"eyeBallLightBrown",
	"eyeBall",
    "eyeBallBlue",
}


modelComposite.eyelashesMaterials = {
	"eyelashesDarkest",
	"eyelashesDarker",
	"eyelashes",
	"eyelashesRed",
	"eyelashesBlond",
}

modelComposite.eyelashesLongMaterials = {
	"eyelashesDarkestLong",
	"eyelashesDarkerLong",
	"eyelashesLong",
	"eyelashesRedLong",
	"eyelashesBlondLong",
}

function modelComposite:generateRemap(sharedState, materialRemap, hash, sapienID)
    local skinColorIndex = math.floor(((sharedState.skinColorFraction - 0.3) / 0.4) * 7)
    skinColorIndex = mjm.clamp(skinColorIndex + 1, 1, 7)

    materialRemap.skin = modelComposite.skinMaterials[skinColorIndex]
    hash = hash .. "s" .. mj:tostring(skinColorIndex)

    local hairColorIndex = mjm.clamp(sharedState.hairColorGene, 1, #modelComposite.hairMaterials)
    local eyeColorIndex = mjm.clamp(sharedState.eyeColorGene or 4, 1, #modelComposite.eyeMaterials)

    if skinColorIndex < 3 then
        materialRemap.mouth = "mouthDarker"
        hairColorIndex = math.min(hairColorIndex, 2)
        if skinColorIndex == 1 then
            hairColorIndex = 1
            eyeColorIndex = math.min(eyeColorIndex, 3)
        end
    elseif skinColorIndex <= 5 then
        if hairColorIndex >= 5 then
            hairColorIndex = 2
        end
    else
        materialRemap.mouth = "mouthLighter"
    end
    
    materialRemap.hair = modelComposite.hairMaterials[hairColorIndex]
    materialRemap.hairNoDecal = modelComposite.hairNoDecalMaterials[hairColorIndex]
    materialRemap.eyebrows = modelComposite.eyebrowsMaterials[hairColorIndex]
    materialRemap.eyelashes = modelComposite.eyelashesMaterials[hairColorIndex]
    materialRemap.eyelashesLong = modelComposite.eyelashesLongMaterials[hairColorIndex]
    hash = hash .. "h" .. mj:tostring(hairColorIndex)
    
    materialRemap.eyeBall = modelComposite.eyeMaterials[eyeColorIndex]
    hash = hash .. "e" .. mj:tostring(eyeColorIndex)


    local lifeStageIndex = sharedState.lifeStageIndex
    if lifeStageIndex == sapienConstants.lifeStages.elder.index then
        materialRemap.hair = "greyHair"
        materialRemap.hairNoDecal = "greyHairNoDecal"
        hash = hash .. "g"
        
        materialRemap.eyelashes = "eyelashesGrey"
        materialRemap.eyelashesLong = "eyelashesGreyLong"
        materialRemap.eyebrows = "eyebrowsGrey"
    end

    return hash
end

--3d5 hash..hashMarker:sap_bwomanBody1.glb_h_r randomIntOfffset15688 pathInfo.count + offsetForNilOption:6
--3d5 hash..hashMarker:sap_bwomanBody1.glb_h_r randomIntOfffset15688 pathInfo.count + offsetForNilOption:6

local defaultRemap = {
    cloak = "clothes",
    clothes = "clothes",
    clothingFur = "clothingFur", 
    clothingFurShort = "clothingFurShort", 
    cloakFur = "clothingFur",
    cloakFurShort = "clothingFurShort",
}

modelComposite.remapsByObjectTypeIndex = {}

function modelComposite:generate(object)

    local sharedState = object.sharedState

    local hash = "sap"
    local genderIndex = maleIndex

    if sharedState.isFemale then
        genderIndex = femaleIndex
    end

    local randomIntOfffset = 15687

    local function getPath(paths, hashMarker)
        local byGender = paths[sharedState.lifeStageIndex]
        if byGender then
            local pathInfo = byGender[genderIndex]
            if pathInfo then
                if pathInfo.customFunction then
                    local fileName = pathInfo.customFunction(object)
                    if fileName then
                        hash = hash .. "_" .. hashMarker .. fileName
                        return modelComposite.basePath .. fileName
                    end
                else
                    if pathInfo.count > 1 then 
                        randomIntOfffset = randomIntOfffset + 1
                        local offsetForNilOption = 0
                        if pathInfo.hasNilOption then
                            offsetForNilOption = 1
                        end
                        --mj:log("path generation:", object.uniqueID, " hash..hashMarker:", hash .. "_" .. hashMarker, " randomIntOfffset", randomIntOfffset, " pathInfo.count + offsetForNilOption:", pathInfo.count + offsetForNilOption)
                        local pathIndex = rng:integerForUniqueID(object.uniqueID, randomIntOfffset, pathInfo.count + offsetForNilOption) + 1
                        hash = hash .. "_" .. mj:tostring(genderIndex) .. "_" .. hashMarker .. mj:tostring(pathIndex)
                        --mj:log("pathIndex:", pathIndex)
                        if pathIndex > pathInfo.count then
                            return nil
                        end
                        return modelComposite.basePath .. pathInfo.base .. pathIndex .. ".glb"
                    else
                        hash = hash .. "_" .. mj:tostring(genderIndex) .. "_" .. hashMarker
                        return modelComposite.basePath .. pathInfo.base .. "1.glb"
                    end
                end
            end
        end
        return nil
    end

    local bodyPath = getPath(modelComposite.bodyPaths, "b")
    local headPath = getPath(modelComposite.headPaths, "h")
    local hairPath = getPath(modelComposite.hairPaths, "r")
    local beardPath = getPath(modelComposite.beardPaths, "f")

    --hairPath = "composite/sapien/womanHair7.glb"
    local cloakPath = nil--"composite/sapien/manCloak1.glb"

    local cloakType = nil
    local inventories = sharedState.inventories
    if inventories then
        local torsoInventory = inventories[sapienInventory.locations.torso.index]
        if torsoInventory then
            for i, gameObjectTypeIndex in ipairs(gameObject.clothingTypesByInventoryLocations[sapienInventory.locations.torso.index]) do
                local cloakCount = torsoInventory.countsByObjectType[gameObjectTypeIndex] or 0
                if cloakCount > 0 then
                    cloakType = gameObjectTypeIndex
                end
            end
        end
    end
    
    local materialRemap = {}

    if cloakType ~= nil then
        if sharedState.lifeStageIndex >= sapienConstants.lifeStages.adult.index then
            if sharedState.isFemale then
                if sharedState.pregnant then
                    cloakPath = "composite/sapien/womanCloak1Pregnant.glb"
                elseif sharedState.hasBaby then
                    cloakPath = "composite/sapien/womanCloak1WithBaby.glb"
                else
                    cloakPath = "composite/sapien/womanCloak1.glb"
                end
            else 
                cloakPath = "composite/sapien/manCloak1.glb"
            end
        else
            cloakPath = "composite/sapien/childCloak1.glb"
        end
        hash = hash .. "_c".. mj:tostring(cloakType)

        local function assignCloakRemaps(baseTable)
            for k,v in pairs(baseTable) do
                materialRemap[k] = v
            end
        end

        local remaps = modelComposite.remapsByObjectTypeIndex[cloakType] or defaultRemap
        --mj:log("cloakType:", cloakType, " remaps:", modelComposite.remapsByObjectTypeIndex[cloakType])
        assignCloakRemaps(remaps)

    end
    

    hash = modelComposite:generateRemap(sharedState, materialRemap, hash, object.uniqueID)

    --mj:log("object.uniqueID:", object.uniqueID, " hairPath:", hairPath, " hash:", hash, " materialRemap:", materialRemap)

    local result = {
        paths = {
            {
                path = bodyPath,
            },
            {
                path = headPath
            }
        },
        materialRemap = materialRemap,
    }

    if hairPath then
        table.insert(result.paths, {
            boneName = "head",
            path = hairPath
        })
    end

    if beardPath then
        table.insert(result.paths, {
            path = beardPath
        })
    end

    if cloakPath then
        table.insert(result.paths, {
            path = cloakPath
        })
    end

    result.hash = hash

    --mj:log("generated composite:", hash)

    return result
end

function modelComposite:addVariantRemap(clothingObjectTypeIndex, materialRemap)
    mj:log("modelComposite:addVariantRemap:", materialRemap)
    modelComposite.remapsByObjectTypeIndex[clothingObjectTypeIndex] = materialRemap
end

function modelComposite:init(gameObject_)
    gameObject = gameObject_

    
    modelComposite.remapsByObjectTypeIndex = {
        [gameObject.types.mammothWoolskin.index] = {
            cloak = "clothesMammoth",
            clothes = "clothesMammoth",
            clothingFur = "clothingFur", 
            clothingFurShort = "clothingFurShort", 
            cloakFur = "clothingMammothFur",
            cloakFurShort = "clothingMammothFurShort",
        },
    }


    modelComposite.bodyPaths = {
        [sapienConstants.lifeStages.child.index] = {
            [maleIndex] = {
                base = "boyBody",
                count = 1,
            },
            [femaleIndex] = {
                base = "girlBody",
                count = 1,
            }
        },
        [sapienConstants.lifeStages.adult.index] = {
            [maleIndex] = {
                base = "manBody",
                count = 1,
            },
            [femaleIndex] = {
                customFunction = function(sapien)
                    if sapien.sharedState.pregnant then
                        return "womanBodyPregnant1.glb"
                    elseif sapien.sharedState.hasBaby then
                        return "womanBodyWithBaby1.glb"
                    else
                        return "womanBody1.glb"
                    end
                end
            }
        },
    }
    
    
    modelComposite.headPaths = {
        [sapienConstants.lifeStages.child.index] = {
            [maleIndex] = {
                base = "boyHead",
                count = 1,
            },
            [femaleIndex] = {
                base = "girlHead",
                count = 1,
            }
        },
        [sapienConstants.lifeStages.adult.index] = {
            [maleIndex] = {
                base = "manHead",
                count = 1,
            },
            [femaleIndex] = {
                base = "womanHead",
                count = 1,
            }
        },
    }
    
    
    modelComposite.hairPaths = {
        [sapienConstants.lifeStages.child.index] = {
            [maleIndex] = {
                base = "boyHair",
                count = 3,
            },
            [femaleIndex] = {
                base = "girlHair",
                count = 3,
            }
        },
        [sapienConstants.lifeStages.adult.index] = {
            [maleIndex] = {
                customFunction = function(sapien)
                    local pathIndex = rng:integerForUniqueID(sapien.uniqueID, 2653, 6) + 1
                    if pathIndex == 6 then
                        pathIndex = 7
                    end
                    return "manHair" .. pathIndex .. ".glb"
                end
            },
            [femaleIndex] = {
                base = "womanHair",
                count = 8,
            }
        },
        [sapienConstants.lifeStages.elder.index] = {
            [maleIndex] = {
                customFunction = function(sapien)
                    local pathIndex = rng:integerForUniqueID(sapien.uniqueID, 2653, 6) + 1
                    if pathIndex == 6 then
                        pathIndex = 7
                    end
                    local baldingResult = rng:integerForUniqueID(sapien.uniqueID, 23453, 4)
                    if baldingResult == 0 then
                        return nil
                    elseif baldingResult == 1 then
                        return "manHair" .. 6 .. ".glb"
                    else
                        return "manHair" .. pathIndex .. ".glb"
                    end
                end
            },
            [femaleIndex] = {
                base = "womanHair",
                count = 8,
            }
        },
    }
    
    modelComposite.beardPaths = {
        [sapienConstants.lifeStages.adult.index] = {
            [maleIndex] = {
                base = "manBeard",
                count = 3,
            },
        },
    }
    
    modelComposite.bodyPaths[sapienConstants.lifeStages.elder.index] = modelComposite.bodyPaths[sapienConstants.lifeStages.adult.index]
    modelComposite.headPaths[sapienConstants.lifeStages.elder.index] = modelComposite.headPaths[sapienConstants.lifeStages.adult.index]
    modelComposite.beardPaths[sapienConstants.lifeStages.elder.index] = modelComposite.beardPaths[sapienConstants.lifeStages.adult.index]
end

return modelComposite