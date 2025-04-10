local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec4 = mjm.vec4
local vec2 = mjm.vec2
local mat3Identity = mjm.mat3Identity
local approxEqual = mjm.approxEqual
local approxEqualEpsilon = mjm.approxEqualEpsilon

local gameObject = mjrequire "common/gameObject"
--local plan = mjrequire "common/plan"
local material = mjrequire "common/material"
local model = mjrequire "common/model"
local locale = mjrequire "common/locale"

--local keyMapping = mjrequire "mainThread/keyMapping"
--local eventManager = mjrequire "mainThread/eventManager"
local audio = mjrequire "mainThread/audio"
local modelPlaceholder = mjrequire "common/modelPlaceholder"
local uiAnimation = mjrequire "mainThread/ui/uiAnimation"


local uiCommon = {}

uiCommon.fontName = locale:getLightFont()--"sapiensLight"
uiCommon.titleFontName = locale:getTitleFont()--"sapiens"
uiCommon.sapiensTitleFontName = "sapiens"
uiCommon.consoleFontName = locale:getConsoleFont()--"console"

MJCache:setFontOffset("sapiensLight", vec2(0.0,0.15)) --offsets all characters in the given font by the fractional amount. After I added diacritics, it increased the vertical height which shifted everything too low. This hack moves everything back up.
MJCache:setFontOffset("sapiens", vec2(0.0,0.05)) 
MJCache:setFontOffset("console", vec2(0.0,0.05)) 

MJCache:setFontReversed("arabic", true) 

uiCommon.standardFadeDuration = 0.5

uiCommon.hoverSoundFile = "audio/sounds/ui/hover.wav"
uiCommon.cancelSoundFile = "audio/sounds/ui/cancel.wav"
uiCommon.orderSoundFile = "audio/sounds/ui/order.wav"
uiCommon.failSoundFile = "audio/sounds/ui/fail.wav"
uiCommon.clickDownSoundFile = "audio/sounds/ui/stone5.wav"
uiCommon.clickReleaseSoundFile = "audio/sounds/ui/stone4.wav"



uiCommon.reticleImagesByTypes = {
    dot = "img/crosshairsDot.png",
    bullseye = "img/crosshairsBullseye.png",
    crosshairs = "img/crosshairsCross.png",
}

function uiCommon:getCrosshairsScale(sizeFraction)
    return (math.pow(2.0, sizeFraction * 2.5) - 0.5) * 34.071293 --works out at 64x64 when sizeFraction is the default of 0.5
end


local selectedButtonColor = mj.highlightColor

uiCommon.mainTitleOffsetX = -20.0
uiCommon.menuBarWidth = 400.0



uiCommon.listBackgroundColors = {vec4(0.03,0.03,0.03,0.5), vec4(0.0,0.0,0.0,0.5)}


uiCommon.selectedTabZOffset = -2.0
uiCommon.unSelectedTabZOffset = -6.0


local function updateButtonColor(buttonIndex, thisButton, buttonMenu)
    local color = mj.textColor
    if buttonIndex == buttonMenu.selectedIndex and buttonIndex ~= buttonMenu.clickedIndex then
        color = selectedButtonColor
        if not thisButton.selected then
            thisButton.text:setText(thisButton.string, material.types.selectedText.index)
            thisButton.selected = true
        end
    else
        if thisButton.selected then
           -- thisButton.button:removeSubview(thisButton.underlineView)
           -- thisButton.underlineView = nil
            thisButton.text:setText(thisButton.string, material.types.standardText.index)
            thisButton.selected = nil
        end
    end
   -- thisButton.text.color = color --todo material
    if  thisButton.controlView then
        thisButton.controlView.color = color
    end
end

local function updateButtonColors(buttonMenu)
    for thisIndex,thisButton in pairs(buttonMenu.buttons) do 
        updateButtonColor(thisIndex,thisButton, buttonMenu)
    end
end


local function resizeBackgroundViews(view, size)
    
    local insetSize = view.userData.insetSize or 40.0
    local bgInsetSize = vec2(insetSize, insetSize)
    local bgTexSize = view.userData.imageTexture.size
    local bgTexInsetSize = vec2(bgInsetSize.x / bgTexSize.x, bgInsetSize.y / bgTexSize.y)
    local bgTexInnerDimensions = vec2(1.0 - bgTexInsetSize.x * 2.0, 1.0 - bgTexInsetSize.y * 2.0)
    local innerDimensions = vec2(size.x - bgInsetSize.x * 2.0, size.y - bgInsetSize.y * 2.0)

    local backgroundViews = view.userData.backgroundViews
    
    backgroundViews.bottomLeftCornerView.size = bgInsetSize
    backgroundViews.bottomLeftCornerView.imageSize = bgTexInsetSize

    backgroundViews.midLeftView.size = vec2(bgInsetSize.x, innerDimensions.y)
    backgroundViews.midLeftView.imageSize = vec2(bgTexInsetSize.x, bgTexInnerDimensions.y)
    backgroundViews.midLeftView.imageOffset = vec2(0.0,bgTexInsetSize.y)
    backgroundViews.midLeftView.baseOffset = vec3(0.0, bgInsetSize.y, 0)
    
    backgroundViews.topLeftCornerView.size = bgInsetSize
    backgroundViews.topLeftCornerView.imageSize = bgTexInsetSize
    backgroundViews.topLeftCornerView.imageOffset = vec2(0.0, 1.0 - bgTexInsetSize.y)
    backgroundViews.topLeftCornerView.baseOffset = vec3(0.0, size.y - bgInsetSize.y, 0)
    
    backgroundViews.bottomView.size = vec2(innerDimensions.x, bgInsetSize.y)
    backgroundViews.bottomView.imageSize = vec2(bgTexInnerDimensions.x, bgTexInsetSize.y)
    backgroundViews.bottomView.imageOffset = vec2(bgTexInsetSize.x, 0.0)
    backgroundViews.bottomView.baseOffset = vec3(bgInsetSize.x, 0.0, 0)

    backgroundViews.middleView.size = innerDimensions
    backgroundViews.middleView.imageSize = bgTexInnerDimensions
    backgroundViews.middleView.imageOffset = bgTexInsetSize
    backgroundViews.middleView.baseOffset = vec3(bgInsetSize.x, bgInsetSize.y, 0.0)

    backgroundViews.topView.size = vec2(innerDimensions.x, bgInsetSize.y)
    backgroundViews.topView.imageSize = vec2(bgTexInnerDimensions.x, bgTexInsetSize.y)
    backgroundViews.topView.imageOffset = vec2(bgTexInsetSize.x, 1.0 - bgTexInsetSize.y)
    backgroundViews.topView.baseOffset = vec3(bgInsetSize.x, size.y - bgInsetSize.y, 0)
    
    backgroundViews.bottomRightCornerView.size = bgInsetSize
    backgroundViews.bottomRightCornerView.imageSize = bgTexInsetSize
    backgroundViews.bottomRightCornerView.imageOffset = vec2(1.0 - bgTexInsetSize.x, 0.0)
    backgroundViews.bottomRightCornerView.baseOffset = vec3(size.x - bgInsetSize.x, 0.0, 0)
    
    backgroundViews.midRightView.size = vec2(bgInsetSize.x, innerDimensions.y)
    backgroundViews.midRightView.imageSize = vec2(bgTexInsetSize.x, bgTexInnerDimensions.y)
    backgroundViews.midRightView.imageOffset = vec2(1.0 - bgTexInsetSize.x,bgTexInsetSize.y)
    backgroundViews.midRightView.baseOffset = vec3(size.x - bgInsetSize.x, bgInsetSize.y, 0)
    
    backgroundViews.topRightCornerView.size = bgInsetSize
    backgroundViews.topRightCornerView.imageSize = bgTexInsetSize
    backgroundViews.topRightCornerView.imageOffset = vec2(1.0 - bgTexInsetSize.x, 1.0 - bgTexInsetSize.y)
    backgroundViews.topRightCornerView.baseOffset = vec3(size.x - bgInsetSize.x, size.y - bgInsetSize.y, 0)

    view.size = size
end


local function setupBackgroundView(view)

    local textureName = view.userData.textureName or "img/ui/uiBox.png"

    local imageTexture = MJCache:getTexture(textureName)

    local bottomLeftCornerView = ImageView.new(view)
    bottomLeftCornerView.imageTexture = imageTexture
    bottomLeftCornerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local midLeftView = ImageView.new(view)
    midLeftView.imageTexture = imageTexture
    midLeftView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local topLeftCornerView = ImageView.new(view)
    topLeftCornerView.imageTexture = imageTexture
    topLeftCornerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local bottomView = ImageView.new(view)
    bottomView.imageTexture = imageTexture
    bottomView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local middleView = ImageView.new(view)
    middleView.imageTexture = imageTexture
    middleView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local topView = ImageView.new(view)
    topView.imageTexture = imageTexture
    topView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local bottomRightCornerView = ImageView.new(view)
    bottomRightCornerView.imageTexture = imageTexture
    bottomRightCornerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local midRightView = ImageView.new(view)
    midRightView.imageTexture = imageTexture
    midRightView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local topRightCornerView = ImageView.new(view)
    topRightCornerView.imageTexture = imageTexture
    topRightCornerView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)

    local views = {
        bottomLeftCornerView = bottomLeftCornerView,
        midLeftView = midLeftView,
        topLeftCornerView = topLeftCornerView,
        bottomView = bottomView,
        middleView = middleView,
        topView = topView,
        bottomRightCornerView = bottomRightCornerView,
        midRightView = midRightView,
        topRightCornerView = topRightCornerView
    }
    
    view.userData.backgroundViews  = views
    view.userData.imageTexture = imageTexture
end

function uiCommon:createBackgroundView(parent, textureName, insetSize)
    local view = View.new(parent)
    view.userData = {
        textureName = textureName,
        insetSize = insetSize,
    } 
    return view
end

function uiCommon:changeBackgroundViewImage(view, textureName)
    if view.textureName ~= textureName then

        local imageTexture = MJCache:getTexture(textureName)

        local views = view.userData.backgroundViews
        for k,backgroundView in pairs(views) do
            backgroundView.imageTexture = imageTexture
        end
    end
end

function uiCommon:resizeBackgroundView(view, size)

    if not view.userData then
        mj:log("background view must be created before it can be resized")
        return 
    end

    if view.userData.backgroundViews then
        resizeBackgroundViews(view, size)
    else
        if size and size.x > 1 and size.y > 1 then
            setupBackgroundView(view)
            resizeBackgroundViews(view, size)
            local newViews = view.userData.backgroundViews
            for k,newView in pairs(newViews) do
                view:orderBack(newView)
            end
        end
    end
end


local hoverButtonZOffsetDefault = 2.0

function uiCommon:createButtonUpdateFunction(buttonInfo, buttonView, hoverButtonZOffsetOrNilForDefault)
    local hoverButtonZOffset = hoverButtonZOffsetOrNilForDefault or hoverButtonZOffsetDefault
    buttonInfo.buttonUpdateDifferenceVelocity = 0.0
    return function(dt)
        local buttonOffset = buttonView.additionalOffset
        local buttonZ = buttonOffset.z

        local function updateGoal(goalOffset)
            if (not approxEqual(goalOffset, buttonZ)) or (not approxEqual(buttonInfo.buttonUpdateDifferenceVelocity, 0.0)) then
                local difference = goalOffset - buttonZ
                local clampedDT = mjm.clamp(dt * 40.0, 0.0, 1.0)
                buttonInfo.buttonUpdateDifferenceVelocity = buttonInfo.buttonUpdateDifferenceVelocity * math.max(1.0 - dt * 20.0, 0.0) + (difference * clampedDT)
                buttonZ = buttonZ + buttonInfo.buttonUpdateDifferenceVelocity * dt * 12.0
                if approxEqualEpsilon(buttonInfo.buttonUpdateDifferenceVelocity, 0.0, 1.0) then
                    buttonInfo.buttonUpdateDifferenceVelocity = 0.0
                    buttonZ = goalOffset
                end
                buttonOffset.z = buttonZ
                buttonView.additionalOffset = buttonOffset
            end
        end

        if buttonInfo.mouseDown or buttonInfo.rightMouseDown then
            updateGoal(0.0)
        elseif buttonInfo.hover then
            updateGoal(hoverButtonZOffset + hoverButtonZOffset)
        else
            updateGoal(hoverButtonZOffset)
        end
    end
end

function uiCommon:createButton(name, 
    index, 
    buttonMenu, 
    relativeView,
    relativePosition,
    fontSize,
    offset)

    if not relativePosition then
        relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    end

    if not fontSize then
        fontSize = 36
    end

    if not offset then
        offset = vec3(0,0,0)
    end

    --[[local button = ImageView.new(buttonMenu.view)
    button.size = vec2(uiCommon.menuBarWidth,fontSize * 1.5)
    button.relativeView = relativeView
    button.relativePosition = relativePosition]]

    

    local button = ModelView.new(buttonMenu.view)
    button:setModel(model:modelIndexForName("ui_button_10x3"))
    local scaleToUseX = uiCommon.menuBarWidth * 0.35
    local scaleToUseY = uiCommon.menuBarWidth * 0.25
    button.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    button.relativeView = relativeView
    button.relativePosition = relativePosition
    button.size = vec2(scaleToUseX * 2.0, scaleToUseY * 2.0 * 0.3)
    button.baseOffset = offset
    

    local buttonString = name

    local buttonText = ModelTextView.new(button)
    buttonText.font = Font(uiCommon.titleFontName, fontSize)
    buttonText:setText(buttonString, material.types.standardText.index)
    buttonText.relativePosition = ViewPosition(relativePosition.h, MJPositionCenter)
    buttonText.baseOffset = vec3(0, 4, 0)


    buttonMenu.buttons[index] = {
        button = button, 
        text = buttonText, 
        string = buttonString
    }

    button.hoverStart = function ()
        local changed = (buttonMenu.selectedIndex ~= index)
        buttonMenu.selectedIndex = index
        updateButtonColors(buttonMenu)
        if changed then
            audio:playUISound(uiCommon.hoverSoundFile)
        end
    end

    button.hoverEnd = function ()
        if buttonMenu.clickedIndex == index then
            buttonMenu.clickedIndex = 0
            updateButtonColors(buttonMenu)
        end
    end

    button.mouseDown = function (buttonIndex)
        if buttonIndex == 0 then
            buttonMenu.clickedIndex = index
            buttonMenu.buttons[index].mouseDown = true
            updateButtonColors(buttonMenu)
            audio:playUISound(uiCommon.clickDownSoundFile)
        end
    end

    button.mouseUp = function (buttonIndex)
        if buttonIndex == 0 then
            buttonMenu.clickedIndex = 0
            buttonMenu.buttons[index].mouseDown = nil
            updateButtonColors(buttonMenu)
            audio:playUISound(uiCommon.clickReleaseSoundFile)
        end
    end

    button.update = uiCommon:createButtonUpdateFunction(buttonMenu.buttons[index], button)

    updateButtonColor(index, buttonMenu.buttons[index], buttonMenu)

    return buttonMenu.buttons[index]
end

function uiCommon:setGameObjectViewObject(objectImageView, object, animationInstance)
    if not object then
        objectImageView:removeModel()
        return
    end
    local gameObjectModelIndex = gameObject:modelIndexForGameObjectAndLevel(object, mj.SUBDIVISIONS - 1, nil)
    if not gameObjectModelIndex then
        objectImageView:removeModel()
        return
    end

    local getNextAnimationFrame = nil
    local animationModelTypeIndex = nil
    if animationInstance then
        animationModelTypeIndex = animationInstance.modelTypeIndex
        getNextAnimationFrame = function()
            return uiAnimation:getNextAnimationFrame(animationInstance)
        end
    end
    
    objectImageView:setModel(gameObjectModelIndex,
        function (modelIndex, placeholderName)
            local placeholderInfo = modelPlaceholder:placeholderInfoForModelAndPlaceholderKey(modelIndex, placeholderName)
            if not placeholderInfo or placeholderInfo.hiddenOnBuildComplete then
                return nil
            end
            return {placeholderInfo.defaultModelIndex, placeholderInfo.scale or 1.0}
        end,
        getNextAnimationFrame,
        animationModelTypeIndex
    )

    local rotation = mat3Identity
    local rotationFunction = gameObject.types[object.objectTypeIndex].objectViewRotationFunction
    if rotationFunction then
        rotation = rotationFunction(object)
    end
    objectImageView.objectRotation = rotation

    local viewOffset = vec3(0.0,0.0,0.0)
    local objectViewOffsetFunction = gameObject.types[object.objectTypeIndex].objectViewOffsetFunction
    if objectViewOffsetFunction then
        viewOffset = objectViewOffsetFunction(object)
    end
    objectImageView.viewOffset = viewOffset

    local cameraOffset = vec3(0.0,0.0,1.0)
    local objectViewCameraOffsetFunction = gameObject.types[object.objectTypeIndex].objectViewCameraOffsetFunction
    if objectViewCameraOffsetFunction then
        cameraOffset = objectViewCameraOffsetFunction(object)
    end

    objectImageView.cameraDirection = cameraOffset

    --[[local accumulator = 0.0
    objectImageView.update = function(dt)
        accumulator = accumulator + dt * 0.2
        local newRotation = mat3Rotate(mat3Identity, math.sin(accumulator) * 0.5, vec3(0.0,1.0,0.0)) * rotation
        objectImageView.rotation = newRotation
    end]]
end

function uiCommon:getNameForObject(object)
    return gameObject:getDisplayName(object)
end

return uiCommon