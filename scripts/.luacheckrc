--luacheck: globals globals max_line_length unused_args ignore

globals = {

    "mjNoise", -- mjNoise(seed, persistance)

    "LuaEnvironment",
    "mj",
    "mjrequire",

    "Database",
    "MJCache",

    "fileUtils",

    "MeshTypeUndefined",
    "MeshTypeTerrain",
    "MeshTypeGameObject",

    "RENDER_TYPE_NONE",
    "RENDER_TYPE_STATIC",
    "RENDER_TYPE_STATIC_TRANSPARENT_BUILD",
    "RENDER_TYPE_DYNAMIC",

    "GameStateMainMenu",
    "GameStateLoading",
    "GameStateLoadedRunning",

    "View",
    "ColorView",
    "ImageView",
    "TextView",
    "GameObjectView",
    "ModelView",
    "ModelTextView",
    "ModelImageView",
    "GlobeView",
    "RenderTargetView",
    "LinesView",
    "TerrainMapView",

    "Font",

    "ViewPosition",
    "MJPositionCenter",
    "MJPositionInnerLeft",
    "MJPositionInnerRight",
    "MJPositionOuterLeft",
    "MJPositionOuterRight",
    "MJPositionBottom",
    "MJPositionTop",
    "MJPositionAbove",
    "MJPositionBelow",

    "MJHorizontalAlignmentLeft",
    "MJHorizontalAlignmentCenter",
    "MJHorizontalAlignmentRight",

    -- debug global functions
    "logPlayer",
    "setSunrise",
    "setSunset",
    "printType",
    "tp",
    "logDebug",
    "spawn",
    "setDebugObject",
    "completeCheat",
    "debugLog",
    "setPref",
    "wakeTribe",
    --end

    "loadstring", --some later versions of luacheck complain about this, but it's valid in LuaJIT/5.1
}

max_line_length = false
unused_args = false

ignore = {"311", "331", "611", "612", "613", "614"}