
local mobChicken = mjrequire "common/mob/mobChicken"
local mobAlpaca = mjrequire "common/mob/mobAlpaca"
local mobMammoth = mjrequire "common/mob/mobMammoth"
local mobCatfish = mjrequire "common/mob/mobCatfish"
local mobCoelacanth = mjrequire "common/mob/mobCoelacanth"
local mobFlagellipinna = mjrequire "common/mob/mobFlagellipinna"
local mobPolypterus = mjrequire "common/mob/mobPolypterus"
local mobRedfish = mjrequire "common/mob/mobRedfish"
local mobTropicalfish = mjrequire "common/mob/mobTropicalfish"
local mobSwordfish = mjrequire "common/mob/mobSwordfish"
local model = mjrequire "common/model"
local modelPlaceholder = mjrequire "common/modelPlaceholder"
local locale = mjrequire "common/locale"
local sapienModelComposite = mjrequire "common/modelComposites/sapien"
local selectionGroup = mjrequire "common/selectionGroup"

local objectSpawner = mjrequire "common/objectSpawner"

local typeMaps = mjrequire "common/typeMaps"
local typeIndexMap = typeMaps.types.mob

local mob = {}

mob.types = {}
mob.gameObjectIndexes = {}
mob.spawningTypeIndexes = {}

mob.typeIndexMap = typeIndexMap
mob.spawnFrequencyWeightTotal = 0.0

local gameObject = nil

mob.soundEventTypes = mj:enum {
	"random",
	"angry",
	"death",
}

mob.mobLoaders = {
	mobChicken,
	mobAlpaca,
	mobMammoth,
	mobCatfish,
	mobCoelacanth,
	mobFlagellipinna,
	mobPolypterus,
	mobRedfish,
	mobTropicalfish,
	mobSwordfish,
}

function mob:setupVariants(skillLearning) --needs to be done after modelPlaceholder has been loaded
	for i,mobType in ipairs(mob.validTypes) do
		local baseObjectTypeIndex = mobType.gameObjectTypeIndex
		if mobType.variants then
			for j,variantInfo in ipairs(mobType.variants) do
				if variantInfo.postfix then
					if mobType.variantAddModelPlaceholders then
						for placeholderBaseKey, placeholderAddInfo in pairs(mobType.variantAddModelPlaceholders) do
							if not modelPlaceholder[placeholderBaseKey] then
								modelPlaceholder[placeholderBaseKey] = {}
							end
							local objectTypeKey = placeholderAddInfo.objectTypeKey .. variantInfo.postfix
							modelPlaceholder[placeholderBaseKey][gameObject.types[objectTypeKey].index] = modelPlaceholder:getRemaps(placeholderAddInfo.modelKey .. variantInfo.postfix)
						end
					end

					if mobType.variantAddSapienClothingRemaps then
						local gameObjectType = gameObject.types[mobType.variantAddSapienClothingRemaps.objectTypeKey .. variantInfo.postfix]
						local materialRemap = {}
						for baseMat, replaceMat in pairs(mobType.variantAddSapienClothingRemaps.materials) do
							materialRemap[baseMat] = replaceMat .. variantInfo.postfix
						end
						sapienModelComposite:addVariantRemap(gameObjectType.index, materialRemap)
					end

					skillLearning:addVariant(baseObjectTypeIndex, variantInfo.gameObjectTypeIndex)

				end
			end
		end
	end
end

function mob:addType(key, mobTypeInfo)
	local mobTypeIndex = typeIndexMap[key]
	if mob.types[key] then
		mj:log("WARNING: overwriting mob type:", key)
	end

	mobTypeInfo.key = key
	mobTypeInfo.index = mobTypeIndex
	mob.types[key] = mobTypeInfo
	mob.types[mobTypeIndex] = mobTypeInfo

	if mobTypeInfo.addGameObjectInfo then
		local addGameObjectInfo = mobTypeInfo.addGameObjectInfo
		addGameObjectInfo.mobTypeIndex = mobTypeIndex
		addGameObjectInfo.excludeFromClientCache = true
		--addGameObjectInfo.baseSelectionGroupTypeIndex = selectionGroup.type[key].index
		addGameObjectInfo.selectionGroupName = locale:get("selectionGroup_" .. key)

		mobTypeInfo.name = addGameObjectInfo.name
		mobTypeInfo.plural = addGameObjectInfo.plural

		mobTypeInfo.gameObjectTypeIndex = gameObject:addGameObject(key, addGameObjectInfo)
		local baseDeadObjectType = gameObject.types[mobTypeInfo.deadObjectTypeIndex]

		mobTypeInfo.deadObjectTypeIndexesByBaseObjectTypeIndex = {
			[mobTypeInfo.gameObjectTypeIndex] = mobTypeInfo.deadObjectTypeIndex
		}


		local deadObjectSpawnChance = 0.001
		if mobTypeInfo.variants then
			deadObjectSpawnChance = deadObjectSpawnChance / #mobTypeInfo.variants
		end

		if not mobTypeInfo.swims then
			objectSpawner:addObjectSpawner({
				objectTypeIndex = mobTypeInfo.deadObjectTypeIndex,
				addLevel = 3,
				requiredBiomeTags = mobTypeInfo.requiredBiomeTags,
				disallowedBiomeTags = mobTypeInfo.disallowedBiomeTags,
				maxSpawnObjectCount = 1,
				spawnChanceFraction = deadObjectSpawnChance,
				minAltitude = 0.0,
				maxAltitude = nil,
			})
		end


		if mobTypeInfo.variants then
			local baseDeadObjectKey = baseDeadObjectType.key
			for i,variantInfo in ipairs(mobTypeInfo.variants) do
				if variantInfo.postfix then
					local variantAddGameObjectInfo = mj:cloneTable(addGameObjectInfo)
					variantAddGameObjectInfo.modelName = variantAddGameObjectInfo.modelName .. variantInfo.postfix
					variantAddGameObjectInfo.selectionGroupName = locale:get("selectionGroup_" .. key .. variantInfo.postfix)
					--variantAddGameObjectInfo.baseSelectionGroupTypeIndex = selectionGroup.type[key].index
					local variantObjectKey = key .. variantInfo.postfix
					local variantGameObjectTypeIndex = gameObject:addGameObject(variantObjectKey, variantAddGameObjectInfo)
					variantInfo.gameObjectTypeIndex = variantGameObjectTypeIndex


					local deadObjectKey = baseDeadObjectKey .. variantInfo.postfix
					local deadObjectInfo = mj:cloneTable(baseDeadObjectType)
					deadObjectInfo.key = nil
					deadObjectInfo.index = nil
					deadObjectInfo.modelName = deadObjectInfo.modelName .. variantInfo.postfix
					local deadObjectTypeIndex = gameObject:addGameObject(deadObjectKey, deadObjectInfo)
					mobTypeInfo.deadObjectTypeIndexesByBaseObjectTypeIndex[variantGameObjectTypeIndex] = deadObjectTypeIndex

					
					if not mobTypeInfo.swims then
						objectSpawner:addObjectSpawner({
							objectTypeIndex = deadObjectTypeIndex,
							addLevel = 3,
							requiredBiomeTags = variantInfo.requiredBiomeTags,
							disallowedBiomeTags = variantInfo.disallowedBiomeTags,
							maxSpawnObjectCount = 1,
							spawnChanceFraction = deadObjectSpawnChance,
							minAltitude = 0.0,
							maxAltitude = nil,
						})
					end

					--mj:log("adding mob variant:", variantInfo)

					if mobTypeInfo.variantAddOutputObjectVariants then
						for j, baseOutputObjectTypeKey in ipairs(mobTypeInfo.variantAddOutputObjectVariants) do
							local outputVariantObjectInfo = mj:cloneTable(gameObject.types[baseOutputObjectTypeKey])
							outputVariantObjectInfo.key = nil
							outputVariantObjectInfo.index = nil
							outputVariantObjectInfo.modelName = outputVariantObjectInfo.modelName .. variantInfo.postfix

							local variantAddObjectKey = baseOutputObjectTypeKey .. variantInfo.postfix
							local nameKey = "object_" .. variantAddObjectKey
							local pluralKey = nameKey .. "_plural"
							outputVariantObjectInfo.name = locale:get(nameKey)
							outputVariantObjectInfo.plural = locale:get(pluralKey)
							--mj:log("gameObject:addGameObject:", baseOutputObjectTypeKey .. variantInfo.postfix, " info:", outputVariantObjectInfo)
							gameObject:addGameObject(variantAddObjectKey, outputVariantObjectInfo)
						end
					end

					if mobTypeInfo.variantAddRemapModels then
						
						local orderedKeys = {}
						for baseModelName, remapMaterialKeysArray in  pairs(mobTypeInfo.variantAddRemapModels) do
							table.insert(orderedKeys, baseModelName)
						end

						table.sort(orderedKeys) -- NOTE!!! This inner loop must be a consistent order on logic/main threads, so that model indexes are the same

						for k, baseModelName in  ipairs(orderedKeys) do
							local remapMaterialKeysArray = mobTypeInfo.variantAddRemapModels[baseModelName]
							local remapTable = {}
							for j,materialBaseKey in ipairs(remapMaterialKeysArray) do
								remapTable[materialBaseKey] = materialBaseKey .. variantInfo.postfix
							end
							--mj:log("mob adding variantAddRemapModels remap baseModelName:", baseModelName, "variant model name:", baseModelName .. variantInfo.postfix, " remapTable:", remapTable)
							model:loadRemap(baseModelName, {
								[baseModelName .. variantInfo.postfix] = remapTable,
							})
						end
					end

				else
					variantInfo.gameObjectTypeIndex = mobTypeInfo.gameObjectTypeIndex
				end
				
			end
		end
	end

	mobTypeInfo.addGameObjectInfo = nil
	
	return mobTypeIndex
end

function mob:load(gameObject_)
	gameObject = gameObject_

	for i, loaderObject in ipairs(mob.mobLoaders) do
		loaderObject:load(mob, gameObject)
	end

	mob.validTypes = typeMaps:createValidTypesArray("mob", mob.types)

	for i,mobType in ipairs(mob.validTypes) do
		table.insert(mob.gameObjectIndexes, mobType.gameObjectTypeIndex)
		
		if mobType.variants then
			for k,variantInfo in ipairs(mobType.variants) do
				if variantInfo.gameObjectTypeIndex ~= mobType.gameObjectTypeIndex then
					table.insert(mob.gameObjectIndexes, variantInfo.gameObjectTypeIndex)
				end
			end
		end


		table.insert(mob.spawningTypeIndexes, mobType.index)
		
		local spawnFrequency = mobType.spawnFrequency or 1.0
		mob.spawnFrequencyWeightTotal = mob.spawnFrequencyWeightTotal + spawnFrequency
	end
end

return mob