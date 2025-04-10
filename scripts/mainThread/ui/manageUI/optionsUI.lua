--local mjm = mjrequire "common/mjm"
--local vec3 = mjm.vec3
--local vec2 = mjm.vec2
--local vec4 = mjm.vec4

local locale = mjrequire "common/locale"
local optionsView = mjrequire "mainThread/ui/optionsView"
local bugReportView = mjrequire "mainThread/ui/bugReportView"

local optionsUI = {}

local manageUI = nil
local contentView = nil
local controller = nil

local bugReportViewContainer = nil
local bugReportViewLoaded = false



function optionsUI:init(gameUI, controller_, world_, manageUI_, contentView_)
    contentView = contentView_
    controller = controller_
    manageUI = manageUI_
    optionsView:load(contentView, world_, gameUI, controller, manageUI, optionsUI)
end

function optionsUI:getTitle()
    return optionsView:getTitle()
end

function optionsUI:show()
    if bugReportViewContainer then
        bugReportViewContainer.hidden = true
    end
    optionsView.mainView.hidden = false
    optionsView:parentBecameVisible()
end

function optionsUI:update()
end

function optionsUI:hide()
    optionsView:parentBecameHidden()
    bugReportView:parentBecameHidden()
end


function optionsUI:displayBugReportPanel()
    if not bugReportViewLoaded then
        bugReportViewContainer = View.new(contentView)
        bugReportViewContainer.size = contentView.size
        bugReportView:load(controller, bugReportViewContainer, false)
        bugReportViewLoaded = true
    end
    optionsView.mainView.hidden = true
    bugReportViewContainer.hidden = false
    manageUI:changeTitle(locale:get("reporting_sendBugReport"), "icon_settings")
    bugReportView:parentBecameVisible()
end

function optionsUI:popUI()
    if not optionsView:backButtonClicked() then
        return false
    end
    return true
end

return optionsUI