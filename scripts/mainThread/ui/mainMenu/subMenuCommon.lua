local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local timer = mjrequire "common/timer"

local audio = mjrequire "mainThread/audio"

local subMenuCommon = {
}

local mainMenu = nil

function subMenuCommon:initSizes(mainMenuSize)
    --mj:log("mainMenuSize:", mainMenuSize)
    --local width = mainMenuSize.x / 2
    subMenuCommon.size = vec2(1080, 800)--vec2(width, width * 0.75)
    subMenuCommon.xOffset = mainMenuSize.x * 0.33
end

local function slideOn(subMenu)
    subMenu.slidingOff = false
    local mainView = subMenu.mainView

    if mainView.hidden then
        mainView.baseOffset = vec3(subMenuCommon.xOffset, 0.0, 0.0) + subMenu.slideOnStartOffset
        mainView.hidden = false
        audio:playUISound("audio/sounds/ui/stone.wav")
    end
    mainView.update = function(dt_)
        subMenu.slideTimer = subMenu.slideTimer + dt_ * 4.0
        local fraction = subMenu.slideTimer
        fraction = math.pow(fraction, 0.6)
        if fraction < 1.0 then
            mainView.baseOffset = vec3(subMenuCommon.xOffset, 0.0, 0.0) + subMenu.slideOnStartOffset * (1.0 - fraction)
        else
            mainView.baseOffset = vec3(subMenuCommon.xOffset, 0, 0)
            mainView.update = nil
            subMenu.slideTimer = 1.0
        end
    end
end

function subMenuCommon:slideOn(subMenu, delay)
    if delay <= 0.001 then
        slideOn(subMenu)
    else
        timer:addCallbackTimer(delay * 0.25, function()
            slideOn(subMenu)
        end)
    end
end


function subMenuCommon:slideOff(subMenu, completionFunction)
    local mainView = subMenu.mainView
    --todo mainMenu needs to call mainMenu:restoreMenuSelection here. probably pass function to init()
    if not subMenu.slidingOff then
        subMenu.slidingOff = true
        audio:playUISound("audio/sounds/ui/stone.wav")
        --mj:log("slide off:", subMenu)
        mainView.update = function(dt_)
            subMenu.slideTimer = subMenu.slideTimer - dt_ * 4.0
            local fraction = subMenu.slideTimer
            fraction = math.pow(fraction, 0.6)
            if fraction > 0.0 then
                mainView.baseOffset = vec3(subMenuCommon.xOffset, 0.0, 0.0) + subMenu.slideOffFinishOffset * (1.0 - fraction)
            else
                --mj:log("slide off complete:", subMenu)
                subMenu.slideTimer = 0.0
                mainView.update = nil
                mainView.hidden = true
                if completionFunction then
                    completionFunction()
                end
                mainMenu:restoreMenuSelection()
            end
        end
    end
end

function subMenuCommon:init(mainMenu_, subMenu, mainMenuViewSize)
    mainMenu = mainMenu_
    subMenu.slidingOff = false
    subMenu.slideTimer = 0.0
    subMenu.slideOnStartOffset = vec3(0.0,-mainMenuViewSize.y * 0.5 - subMenu.mainView.size.y * 0.5,0.0)
    subMenu.slideOffFinishOffset = vec3(0.0,-mainMenuViewSize.y * 0.5 - subMenu.mainView.size.y * 0.5,0.0)
end

return subMenuCommon