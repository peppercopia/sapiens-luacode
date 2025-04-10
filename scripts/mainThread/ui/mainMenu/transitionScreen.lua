local mjm = mjrequire "common/mjm"
local vec4 = mjm.vec4

local transitionScreen = {}

local mainView = nil
local backgroundColorToFadeTo = vec4(0.0,0.0,0.0,1.0)

function transitionScreen:init(controller)
    mainView = ColorView.new(controller.mainView)

    mainView.size = controller.virtualSize
    mainView.hidden = true
end

function transitionScreen:fadeIn(doneFunctionOrNil)
    mainView.color = vec4(0.8,0.8,0.8,1.0)
    mainView.hidden = false
    local fadeTimer = 0.0
    mainView.update = function(dt)
        fadeTimer = fadeTimer + dt * 1.0
        if fadeTimer >= 1.0 then
            mainView.color = backgroundColorToFadeTo
            if fadeTimer >= 1.1 then
                mainView.update = nil
                if doneFunctionOrNil then
                    doneFunctionOrNil()
                end
            end
        else
            mainView.color = backgroundColorToFadeTo * fadeTimer
        end
    end
end

function transitionScreen:fadeOut(doneFunctionOrNil)
    local fadeTimer = 0.0
    mainView.update = function(dt)
        fadeTimer = fadeTimer + dt
        if fadeTimer >= 1.0 then
            mainView.hidden = true
            mainView.update = nil
            if doneFunctionOrNil then
                doneFunctionOrNil()
            end
        else
            mainView.color = backgroundColorToFadeTo * (1.0 - fadeTimer)
        end
    end
end

return transitionScreen