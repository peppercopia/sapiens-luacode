
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"

local uiMenuItem = {}

local function updateMenuItemBackground(colorView)
    local buttonTable = colorView.userData
    if buttonTable.mouseDown then
        colorView.color = buttonTable.menuItemMouseDownColor
    elseif buttonTable.selected or buttonTable.hover then
        colorView.color = buttonTable.menuItemHoverColor
    else
        colorView.color = buttonTable.menuItemBaseColor
    end
end

function uiMenuItem:makeMenuItemBackground(colorView, scrollViewOrNil, listIndex, hoverColor, mouseDownColor, clickFunction)

    local buttonTable = colorView.userData
    if not buttonTable then
        buttonTable = {}
        colorView.userData = buttonTable
    end

    buttonTable.menuItemScrollView = scrollViewOrNil
    buttonTable.menuItemListIndex = listIndex
    buttonTable.isMenuItemBackground = true
    buttonTable.menuItemBaseColor = colorView.color
    buttonTable.menuItemHoverColor = hoverColor
    buttonTable.menuItemMouseDownColor = mouseDownColor
    buttonTable.menuItemClickFunction = clickFunction

    if hoverColor then
        colorView.hoverStart = function ()
            buttonTable.hover = true
            updateMenuItemBackground(colorView)
            if buttonTable.hoverStartUserFunction then
                buttonTable.hoverStartUserFunction()
            end
        end

        colorView.hoverEnd = function ()
            buttonTable.hover = nil
            updateMenuItemBackground(colorView)
            if buttonTable.hoverEndUserFunction then
                buttonTable.hoverEndUserFunction()
            end
        end
    end

    if mouseDownColor then
        colorView.mouseDown = function (buttonIndex)
            if buttonIndex == 0 then
                buttonTable.mouseDown = true
                updateMenuItemBackground(colorView)
            end
        end

        colorView.mouseUp = function (buttonIndex)
            if buttonIndex == 0 then
                buttonTable.mouseDown = nil
                updateMenuItemBackground(colorView)
            end
        end
    end

    colorView.click = function()
        clickFunction(true)
    end
end


function uiMenuItem:setMenuItemBackgroundSelected(colorView, selected)
    local buttonTable = colorView.userData
    if (selected and not buttonTable.selected) or (buttonTable.selected and not selected) then
        buttonTable.selected = selected
        updateMenuItemBackground(colorView)
        if selected and buttonTable.menuItemScrollView then
            uiScrollView:scrollToVisible(buttonTable.menuItemScrollView, buttonTable.menuItemListIndex, colorView)
        end
    end
end

function uiMenuItem:setHoverFunctions(colorView, hoverStartOrNil, hoverEndOrNil)
    local buttonTable = colorView.userData
    buttonTable.hoverStartUserFunction = hoverStartOrNil
    buttonTable.hoverEndUserFunction = hoverEndOrNil
end

function uiMenuItem:callMenuItemClickFunction(colorView)
    local buttonTable = colorView.userData
    if buttonTable.menuItemClickFunction then
        buttonTable.menuItemClickFunction(false)
    end
end

return uiMenuItem