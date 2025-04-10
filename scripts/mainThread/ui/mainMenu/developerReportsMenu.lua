--************************************************************** NOTE **************************************************************
-- This is only ever visible and functional when used by the developer, and is used for debugging purposes. Not visible to players.
--**************************************************************      **************************************************************

local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiMenuItem = mjrequire "mainThread/ui/uiCommon/uiMenuItem"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local subMenuCommon = mjrequire "mainThread/ui/mainMenu/subMenuCommon"
local uiTextEntry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local worldConfig = mjrequire "common/worldConfig"
--local clientGameSettings = mjrequire "mainThread/clientGameSettings"

local developerReportsMenu = {}

local pinnedReports = nil
local completedReports = nil

local controller = nil
local reportList = nil
local reportListView = nil
local worldNameTextView = nil
local lastPlayedTextView = nil
local createdTextView = nil
local importedTextView = nil
local warningTextView = nil

local importButton = nil
local openLogsButton = nil
local openDirectoryButton = nil
local loadWorldButton = nil
local pinToggleButton = nil
local completedToggleButton = nil

local selectedInfoIndex = nil
local tableViewItemInfos = {}
local hoverColor = mj.highlightColor * 0.8
local mouseDownColor = mj.highlightColor * 0.6
local selectedColor = mj.highlightColor * 0.8
local selectedPinnedColor = vec4(1.0,0.5,0.0,1.0) * 0.8
local selectedCompletedColor = vec4(0.0,1.0,0.5,1.0) * 0.8


local loadConfirmButtonFunc = nil

local showSimpleCrashReports = true
local searchText = nil

local function updateButtonColors(buttonView, baseColor)
    buttonView.color = baseColor
    buttonView.hoverStart = function ()
        buttonView.color = hoverColor
    end

    buttonView.hoverEnd = function ()
        buttonView.color = baseColor
    end

    buttonView.mouseDown = function (buttonIndex)
        if buttonIndex == 0 then
            buttonView.color = mouseDownColor
        end
    end

    buttonView.mouseUp = function (buttonIndex)
        if buttonIndex == 0 then
            buttonView.color = baseColor
        end
    end
end


local function checkForMods(reportName)
    local modsList = controller:getEnabledModListFromConfig(reportName)
    mj:log("modsList:", modsList)
    if modsList and #modsList > 0 then
        warningTextView.text = string.format("Uses %d mods", #modsList)
        uiStandardButton:setTextColor(loadWorldButton, vec4(1.0,0.5,0.1,1.0))
    else
        warningTextView.text =""
        uiStandardButton:setTextColor(loadWorldButton, nil)
    end
end

local function updateSelectedIndex(newInfoIndex)
   -- if newInfoIndex ~= selectedInfoIndex then
        if selectedInfoIndex then
            local tableViewItemInfo = tableViewItemInfos[selectedInfoIndex]
            updateButtonColors(tableViewItemInfo.backgroundView, tableViewItemInfo.defaultColor)
        end

        selectedInfoIndex = newInfoIndex

        if selectedInfoIndex then
            local tableViewItemInfo = tableViewItemInfos[selectedInfoIndex]
            if tableViewItemInfo then
                local worldInfo = reportList[selectedInfoIndex]
                local colorToUse = selectedColor
                
                if worldInfo.completed then
                    colorToUse = selectedCompletedColor
                elseif worldInfo.pinned then
                    colorToUse = selectedPinnedColor
                end
                updateButtonColors(tableViewItemInfo.backgroundView, colorToUse)

                worldNameTextView.text = reportList[selectedInfoIndex].name

                local now = os.time()
                local lastPlayedString = "N/A"

                local date = reportList[selectedInfoIndex].date
                local timeSincePlayed = (now - date)

                if timeSincePlayed >= 0 then
                    local found = false
                    if timeSincePlayed < 48 * 60 * 60 then
                        local currentTimeTable = os.date("*t", now)
                        local currentHour = currentTimeTable.hour
                        local currentMinute = currentTimeTable.min
                        if timeSincePlayed < (currentHour * 60 + currentMinute) * 60 then
                            lastPlayedString = "Today"
                            found = true
                        elseif timeSincePlayed < ((24 + currentHour) * 60 + currentMinute) * 60 then
                            lastPlayedString = "Yesterday"
                            found = true
                        end
                    end
                    if not found then
                        local count = math.floor(timeSincePlayed / (24 * 60 * 60))
                        if count < 2 then
                            count = 2
                        end
                        lastPlayedString = mj:tostring(count) .. " days ago"
                    end
                end

                
                local timeStamp = os.date("%c", date)
                
                lastPlayedTextView.text = "Reported: " .. lastPlayedString
                createdTextView.text = timeStamp

                uiStandardButton:setDisabled(importButton, false)

                if not fileUtils.fileExistsAtPath(reportList[selectedInfoIndex].reportDirectoryName) then
                    local zipFileName = reportList[selectedInfoIndex].reportDirectoryName .. ".zip"
                    fileUtils.unzipArchive(zipFileName, reportList[selectedInfoIndex].reportDirectoryName)
                    mj:log("unzip success:", fileUtils.fileExistsAtPath(reportList[selectedInfoIndex].reportDirectoryName))
                end

                local downloaded = fileUtils.fileExistsAtPath(reportList[selectedInfoIndex].worldDirectoryName)
                if downloaded then
                    importedTextView.text = "Downloaded"
                    uiStandardButton:setDisabled(openDirectoryButton, false)
                    if fileUtils.fileExistsAtPath(reportList[selectedInfoIndex].worldDirectoryName .. "/serverdb") then
                        uiStandardButton:setDisabled(loadWorldButton, false)
                        importedTextView.text = importedTextView.text .. " (Contains World Save)"
                    else
                        uiStandardButton:setDisabled(loadWorldButton, true)
                        importedTextView.text = importedTextView.text .. " (No World Save)"
                    end
                else
                    importedTextView.text = "Not downloaded"
                    uiStandardButton:setDisabled(openDirectoryButton, true)
                    uiStandardButton:setDisabled(loadWorldButton, true)
                end
                
                checkForMods(reportList[selectedInfoIndex].name)

                uiStandardButton:setToggleState(pinToggleButton, reportList[selectedInfoIndex].pinned)
                uiStandardButton:setToggleState(completedToggleButton, reportList[selectedInfoIndex].completed)

            end
            
        end
    --end
end

local function removeOldStuff()
    local worldID = reportList[selectedInfoIndex].name
    for sessionIndex=0,999 do
        local dbKey = "sessionInfo_" .. worldID .. string.format("%d", sessionIndex)
        if controller.appDatabase:hasKey(dbKey) then
            controller.appDatabase:removeDataForKey(dbKey)
        elseif sessionIndex > 1 then
            break
        end
    end

    local sessionIndexKey = "sessionCounter_" .. worldID
    controller.appDatabase:removeDataForKey(sessionIndexKey)
end


local function capture(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = f:read('*a')
    if not s then
        mj:error("no s a")
        f:close()
        f = assert(io.popen(cmd, 'r'))
        s = f:read('*a')
        if not s then
            mj:error("no s b")
        end
    end
    f:close()
    return s
end

local function downloadAndExtract(reportInfo)

    local reportFileName = reportInfo.version .. "_" .. reportInfo.reportID .. "_world_" .. reportInfo.title
    local worldDirectoryName = reportInfo.worldDirectoryName

    local command = "'" .. fileUtils.getSavePath("SapiensBugReports/getWorld.sh") .. "' '" .. reportFileName .. "'"
    mj:log("command:", command)
    local outputData = capture(command)
    mj:log("outputData:", outputData)

    local zipFileName = fileUtils.getSavePath("SapiensBugReports/worlds/" .. reportFileName .. ".zip")

    local downloaded = fileUtils.fileExistsAtPath(zipFileName)
    if downloaded then
        if fileUtils.fileExistsAtPath(worldDirectoryName) then
            fileUtils.removeDirectory(worldDirectoryName)
        end
        fileUtils.unzipArchive(zipFileName, worldDirectoryName)
        local unzipped = fileUtils.fileExistsAtPath(worldDirectoryName)
        if unzipped then
            importedTextView.text = "Downloaded"
            uiStandardButton:setDisabled(openDirectoryButton, false)
            
            if fileUtils.fileExistsAtPath(worldDirectoryName .. "/serverdb") then
                removeOldStuff()
                local configPath = worldDirectoryName .. "/config.lua"
                if fileUtils.fileExistsAtPath(configPath) then
                    fileUtils.removeFile(configPath)
                end

                worldConfig:initForWorldCreation(configPath, reportInfo.reportID .. "_" .. reportInfo.title, nil)

                uiStandardButton:setDisabled(loadWorldButton, false)
                importedTextView.text = importedTextView.text .. " (Contains World Save)"
            else
                uiStandardButton:setDisabled(loadWorldButton, true)
                importedTextView.text = importedTextView.text .. " (No World Save)"
            end
        else
            importedTextView.text = "Failed to unzip"
        end
    else
        importedTextView.text = "Failed to download"
    end
    checkForMods(worldDirectoryName)
end

local function getFiles()

    local function splitLine(line) -- (\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)\s+(\d+) (\S+).zip
        mj:log(line)
        local matches = {line:match("(%d+)%s+(%S+)%s+(%d+)%s+(%d+):(%d+):(%d+)%s+(%d+) .+/([^/]+)%.zip")}
        if matches and #matches == 8 then
            local monthNames = mj:enum {"Jan", "Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec",}
            local date = os.time({day=matches[3],month=monthNames[matches[2]],year=matches[7],hour=matches[4],min=matches[5],sec=matches[6]})
            local name = matches[8]

            local nameSplit = {name:match("([^_]+)_([^_]+)_(%S+)")}
            
            local worldDirectoryName = fileUtils.getSavePath("players/" .. controller:getPlayerID() .. "/worlds/" .. name)
            local reportDirectoryName = fileUtils.getSavePath("SapiensBugReports/reports/" .. name)

            local pinned = pinnedReports[name]
            local completed = completedReports[name]

            return {
                date = date,
                name = name,
                pinned = pinned,
                completed = completed,
                size = tonumber(matches[1]),
                worldDirectoryName = worldDirectoryName,
                reportDirectoryName = reportDirectoryName,
                version = nameSplit[1],
                reportID = nameSplit[2],
                title = nameSplit[3],
            }
        else
            mj:error("not a match:", line)
        end
        return nil
    end



    local outputData = capture("'" .. fileUtils.getSavePath("SapiensBugReports/update.sh") .. "'")

    local lines = {}

    for line in outputData:gmatch("[^\r\n]+") do
        local lineTable = splitLine(line)
        if lineTable then
            table.insert(lines, lineTable)
        end
    end
    --mj:log(outputData)

    
    local function sortByDate(a,b)
        return a.date > b.date
    end

    table.sort(lines, sortByDate)

    return lines
end

local function updateList(selectName)
    local counter = 1
    uiScrollView:removeAllRows(reportListView)

    local newSelectionIndex = nil

    local function addReport(infoIndex,worldInfo)
        local matchesSearch = true
        if searchText then
            if not string.find(worldInfo.name, searchText) then
                matchesSearch = false
            end
        end

        if matchesSearch then
            if not showSimpleCrashReports then
                local foundIndex, stringEnd = string.find(worldInfo.name, "_Crash")
                if foundIndex and stringEnd == string.len(worldInfo.name) then
                    matchesSearch = false
                end
            end
        end

        if matchesSearch then
            if not newSelectionIndex then
                newSelectionIndex = infoIndex
            end

            if selectName and selectName == worldInfo.name then
                newSelectionIndex = infoIndex
            end

            local backgroundView = ColorView.new(reportListView)
            local defaultColor = vec4(0.0,0.0,0.0,0.5)
            if counter % 2 == 1 then
                defaultColor = vec4(0.03,0.03,0.03,0.5)
            end

            
            if worldInfo.completed then
                if counter % 2 == 1 then
                    defaultColor = vec4(0.1,0.2,0.0,0.5)
                else
                    defaultColor = vec4(0.2,0.4,0.0,0.5)
                end
            elseif worldInfo.pinned then
                if counter % 2 == 1 then
                    defaultColor = vec4(0.2,0.1,0.0,0.5)
                else
                    defaultColor = vec4(0.4,0.2,0.0,0.5)
                end
            end

            backgroundView.color = defaultColor

            backgroundView.size = vec2(reportListView.size.x - 20, 30)
            backgroundView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)

            uiScrollView:insertRow(reportListView, backgroundView, nil)
            --backgroundView.baseOffset = vec3(0,(-counter + 1) * 30,0)

            uiMenuItem:makeMenuItemBackground(backgroundView, reportListView, counter, hoverColor, mouseDownColor, function(wasClick)
                updateSelectedIndex(infoIndex)
            end)

            local nameTextView = TextView.new(backgroundView)
            nameTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
            nameTextView.baseOffset = vec3(0,0,0)
            nameTextView.font = Font(uiCommon.fontName, 16)

            nameTextView.color = vec4(1.0,1.0,1.0,1.0)
            nameTextView.text = worldInfo.name .. string.format( " %.2f mb", (worldInfo.size / 1024 / 1024))

            tableViewItemInfos[infoIndex] = {
                backgroundView = backgroundView,
                defaultColor = defaultColor,
                nameTextView = nameTextView,
            }

            counter = counter + 1
        end
    end

    for infoIndex,worldInfo in pairs(reportList) do
        if worldInfo.pinned then
            addReport(infoIndex,worldInfo)
            if counter >= 500 then
                break
            end
        end
    end

    for infoIndex,worldInfo in pairs(reportList) do
        if not worldInfo.pinned then
            addReport(infoIndex,worldInfo)
            if counter >= 500 then
                break
            end
        end
    end

    updateSelectedIndex(newSelectionIndex)
end

function developerReportsMenu:init(mainMenu)

    pinnedReports = controller.appDatabase:dataForKey("pinnedReports") or {}
    completedReports = controller.appDatabase:dataForKey("completedReports") or {}


    local backgroundSize = subMenuCommon.size

    local reportsPath = fileUtils.getSavePath("reports")
    fileUtils.createDirectoriesIfNeededForDirPath(reportsPath)

    reportList = getFiles()
    --mj:log(lines)
    
    local mainView = ModelView.new(mainMenu.mainView)
    developerReportsMenu.mainView = mainView
   -- mainView:setRenderTargetBacked(true)
   
    local sizeToUse = backgroundSize
    local scaleToUseX = sizeToUse.x * 0.5
    local scaleToUseY = sizeToUse.y * 0.5 / (9.0/16.0)
    mainView:setModel(model:modelIndexForName("ui_bg_lg_16x9"))

    mainView.scale3D = vec3(scaleToUseX,scaleToUseY,scaleToUseX)
    mainView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    mainView.size = backgroundSize
    mainView.hidden = true
    
    local titleTextView = ModelTextView.new(mainView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleTextView.baseOffset = vec3(0,-50, 0)
    titleTextView:setText("Reports", material.types.standardText.index)

    subMenuCommon:init(mainMenu, developerReportsMenu, mainMenu.mainView.size)

    local buttonSize = vec2(180, 40)
    
    local leftPane = ModelView.new(mainView)
    leftPane:setModel(model:modelIndexForName("ui_inset_lg_1x1"))
    local sizeY = mainView.size.y - 300.0
    sizeY = math.floor(sizeY / 30.0) * 30.0
    local leftPaneInnerSize = vec2(mainView.size.x * 0.6 - 80, sizeY)
    leftPane.size = leftPaneInnerSize + vec2(20.0,10.0)
    local scaleToUsePaneX = leftPane.size.x * 0.5
    local scaleToUsePaneY = leftPane.size.y * 0.5 
    leftPane.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    leftPane.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    leftPane.baseOffset = vec3(50.0, 0.0, 0.0)

    reportListView = uiScrollView:create(leftPane, leftPaneInnerSize, MJPositionInnerLeft)
    reportListView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)

    local textEntrySize = vec2(200.0,24.0)

    local searchTextEntry = uiTextEntry:create(leftPane, textEntrySize, uiTextEntry.types.standard_10x3)
    uiTextEntry:setMaxChars(searchTextEntry, 30)
    searchTextEntry.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
    searchTextEntry.relativeView = reportListView
    searchTextEntry.baseOffset = vec3(0, 14, 0)
    uiTextEntry:setAllowsEmpty(searchTextEntry, true)
    uiTextEntry:setText(searchTextEntry, "")
    uiTextEntry:setFunction(searchTextEntry, function(newSearchText)
        local newSearchTextToUse = newSearchText
        if newSearchTextToUse == "" then
            newSearchTextToUse = nil
        end
        searchText = newSearchTextToUse
        updateList()
    end)

    
    local showCrashToggleButton = uiStandardButton:create(leftPane, vec2(26,26), uiStandardButton.types.toggle)
    showCrashToggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionAbove)
    showCrashToggleButton.relativeView = searchTextEntry
    showCrashToggleButton.baseOffset = vec3(4, 0, 0)
    uiStandardButton:setToggleState(showCrashToggleButton, true)
    uiStandardButton:setClickFunction(showCrashToggleButton, function()
        showSimpleCrashReports = uiStandardButton:getToggleState(showCrashToggleButton)
        mj:log("showSimpleCrashReports:", showSimpleCrashReports)
        updateList()
    end)
    
    local showCrashTextView = TextView.new(leftPane)
    showCrashTextView.baseOffset = vec3(0,180, 0)
    showCrashTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    showCrashTextView.relativeView = showCrashToggleButton
    showCrashTextView.baseOffset = vec3(4, 0, 0)
    showCrashTextView.font = Font(uiCommon.fontName, 16)
    showCrashTextView.color = vec4(1.0,1.0,1.0,1.0)
    showCrashTextView.text = "Show simple crashes"
    
    local rightPane = View.new(mainView)
    rightPane.size = vec2(mainView.size.x * 0.4 - 80, sizeY) + vec2(20.0,10.0)
    rightPane.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
    rightPane.baseOffset = vec3(-50.0, 0.0, 0.0)

    worldNameTextView = TextView.new(rightPane)
    worldNameTextView.baseOffset = vec3(0,180, 0)
    worldNameTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
    worldNameTextView.font = Font(uiCommon.fontName, 16)
    worldNameTextView.color = vec4(1.0,1.0,1.0,1.0)

    
    lastPlayedTextView = TextView.new(rightPane)
    lastPlayedTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    lastPlayedTextView.relativeView = worldNameTextView
    lastPlayedTextView.baseOffset = vec3(0,-10,0)
    lastPlayedTextView.font = Font(uiCommon.fontName, 16)
    lastPlayedTextView.color = vec4(1.0,1.0,1.0,1.0)
    
    createdTextView = TextView.new(rightPane)
    createdTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    createdTextView.relativeView = lastPlayedTextView
    createdTextView.baseOffset = vec3(0,-10,0)
    createdTextView.font = Font(uiCommon.fontName, 16)
    createdTextView.color = vec4(1.0,1.0,1.0,1.0)

    importedTextView = TextView.new(rightPane)
    importedTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    importedTextView.relativeView = createdTextView
    importedTextView.baseOffset = vec3(0,-10,0)
    importedTextView.font = Font(uiCommon.fontName, 16)
    importedTextView.color = vec4(1.0,1.0,1.0,1.0)

    warningTextView = TextView.new(rightPane)
    warningTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    warningTextView.relativeView = importedTextView
    warningTextView.baseOffset = vec3(0,-10,0)
    warningTextView.font = Font(uiCommon.fontName, 16)
    warningTextView.color = vec4(1.0,0.5,0.1,1.0)
    warningTextView.size = vec2(0,0)
    

    importButton = uiStandardButton:create(rightPane, buttonSize)
    importButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    importButton.relativeView = warningTextView
    importButton.baseOffset = vec3(0.0,-60, 0)
    uiStandardButton:setText(importButton, "Download")
    uiStandardButton:setClickFunction(importButton, function()
        uiStandardButton:setDisabled(importButton, true)
        downloadAndExtract(reportList[selectedInfoIndex])
    end)

    openDirectoryButton = uiStandardButton:create(rightPane, buttonSize)
    openDirectoryButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    openDirectoryButton.relativeView = importButton
    openDirectoryButton.baseOffset = vec3(0.0,-10, 0)
    uiStandardButton:setText(openDirectoryButton, "Open Directory")
    uiStandardButton:setClickFunction(openDirectoryButton, function()
        fileUtils.openFile(reportList[selectedInfoIndex].worldDirectoryName)
    end)


    openLogsButton = uiStandardButton:create(rightPane, buttonSize)
    openLogsButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    openLogsButton.relativeView = openDirectoryButton
    openLogsButton.baseOffset = vec3(0.0,-10, 0)
    uiStandardButton:setText(openLogsButton, "Open Logs")
    uiStandardButton:setClickFunction(openLogsButton, function()
        if package.config:sub(1,1) == "\\" then --windows
            os.execute('"C:\\Users\\david\\AppData\\Local\\Programs\\Microsoft VS Code\\bin\\code" ' .. reportList[selectedInfoIndex].reportDirectoryName)
        else
            os.execute('/usr/local/bin/code \"' .. reportList[selectedInfoIndex].reportDirectoryName .. "\"")
        end
    end)

    

    loadWorldButton = uiStandardButton:create(rightPane, buttonSize)
    loadWorldButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    loadWorldButton.relativeView = openLogsButton
    loadWorldButton.baseOffset = vec3(0.0,-10, 0)
    uiStandardButton:setText(loadWorldButton, "Load World")
    uiStandardButton:setClickFunction(loadWorldButton, function()
        developerReportsMenu:hide(false)
        loadConfirmButtonFunc(reportList[selectedInfoIndex].name)
    end)

    
    pinToggleButton = uiStandardButton:create(rightPane, vec2(26,26), uiStandardButton.types.toggle)
    pinToggleButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionBelow)
    pinToggleButton.relativeView = loadWorldButton
    pinToggleButton.baseOffset = vec3(-30, -10, 0)
    uiStandardButton:setToggleState(pinToggleButton, false)
    uiStandardButton:setClickFunction(pinToggleButton, function()
        if selectedInfoIndex then
            local pinned = uiStandardButton:getToggleState(pinToggleButton)
            reportList[selectedInfoIndex].pinned = pinned
            pinnedReports[reportList[selectedInfoIndex].name] = pinned
            controller.appDatabase:setDataForKey(pinnedReports, "pinnedReports")
            updateList(reportList[selectedInfoIndex].name)
        end
    end)
    
    local pinTextView = TextView.new(rightPane)
    pinTextView.baseOffset = vec3(0,180, 0)
    pinTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    pinTextView.relativeView = pinToggleButton
    pinTextView.baseOffset = vec3(4, 0, 0)
    pinTextView.font = Font(uiCommon.fontName, 16)
    pinTextView.color = vec4(1.0,1.0,1.0,1.0)
    pinTextView.text = "Pin"

    
    completedToggleButton = uiStandardButton:create(rightPane, vec2(26,26), uiStandardButton.types.toggle)
    completedToggleButton.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    completedToggleButton.relativeView = pinTextView
    completedToggleButton.baseOffset = vec3(4, 0, 0)
    uiStandardButton:setToggleState(completedToggleButton, false)
    uiStandardButton:setClickFunction(completedToggleButton, function()
        if selectedInfoIndex then
            local completed = uiStandardButton:getToggleState(completedToggleButton)
            reportList[selectedInfoIndex].completed = completed
            completedReports[reportList[selectedInfoIndex].name] = completed
            controller.appDatabase:setDataForKey(completedReports, "completedReports")
            updateList(reportList[selectedInfoIndex].name)
        end
    end)
    
    local completedTextView = TextView.new(rightPane)
    completedTextView.baseOffset = vec3(0,180, 0)
    completedTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    completedTextView.relativeView = completedToggleButton
    completedTextView.baseOffset = vec3(4, 0, 0)
    completedTextView.font = Font(uiCommon.fontName, 16)
    completedTextView.color = vec4(1.0,1.0,1.0,1.0)
    completedTextView.text = "Complete"

    updateList()

    

end

function developerReportsMenu:show(controller_, mainMenu, loadConfirmButtonFunc_, delay)
    loadConfirmButtonFunc = loadConfirmButtonFunc_
    if not developerReportsMenu.mainView then
        controller = controller_
        developerReportsMenu:init(mainMenu)
    end
    subMenuCommon:slideOn(developerReportsMenu, delay)
end

function developerReportsMenu:hide()
    if developerReportsMenu.mainView and (not developerReportsMenu.mainView.hidden) then
        subMenuCommon:slideOff(developerReportsMenu)
        return true
    end
    return false
end

function developerReportsMenu:backButtonClicked()
    developerReportsMenu:hide()
end

function developerReportsMenu:hidden()
    return not (developerReportsMenu.mainView and (not developerReportsMenu.mainView.hidden))
end

return developerReportsMenu