------------------------------------------------------------------------------------------------------------------------
-- uiTextView is a WIP/untested general wrapper for TextView and ModelTextView with additional features. 
-- To use ModelTextView, pass through a material, otherwise it will use TextView. 
-- ModelTextView is used for a stylized embossed text for large titles or insets, but is not as fully featured as TextView
------------------------------------------------------------------------------------------------------------------------

--[[

    .addStaticFunction("new", &MJTextView::luaNew)
	.addFunction("setText", &MJModelTextView::setText)
    .addProperty("text", &MJTextView::getText, &MJTextView::setText)
    .addFunction("addColoredText", &MJTextView::addColoredText)
    .addProperty("font", &MJTextView::getFontNameAndSize, &MJTextView::setFontNameAndSize)
    .addProperty("textAlignment", &MJTextView::getTextAlignment, &MJTextView::setTextAlignment)
    .addProperty("wrapWidth", &MJTextView::getWrapWidth, &MJTextView::setWrapWidth)
	.addProperty("fontGeometryScale", &MJTextView::getFontGeometryScale, &MJTextView::setFontGeometryScale)

    .addProperty("color", &MJTextView::getTextColor, &MJTextView::setTextColor)
	.addFunction("getRectForCharAtIndex", &MJTextView::getRectForCharAtIndex)
    .addFunction("getCharIndexForPos", &MJTextView::getCharIndexForPos)
    .addFunction("resetVerticalCursorMovementAnchors", &MJTextView::resetVerticalCursorMovementAnchors)
    .addFunction("getCursorOffsetForVerticalCursorMovement", &MJTextView::getCursorOffsetForVerticalCursorMovement)

	.addStaticFunction("new", &MJModelTextView::luaNew)
	.addFunction("setText", &MJModelTextView::setText)
	.addFunction("addText", &MJModelTextView::addText)
	.addProperty("font", &MJModelTextView::getFontNameAndSize, &MJModelTextView::setFontNameAndSize)
	.addProperty("textAlignment", &MJModelTextView::getTextAlignment, &MJModelTextView::setTextAlignment)
	.addProperty("wrapWidth", &MJModelTextView::getWrapWidth, &MJModelTextView::setWrapWidth)
	.addProperty("fontGeometryScale", &MJModelTextView::getFontGeometryScale, &MJModelTextView::setFontGeometryScale)

]]

local uiTextView = {}

function uiTextView:create(parentView, options)

    local textView = nil
    local userTable = {}
    textView.userData = userTable

    if options.material then
        textView = ModelTextView.new(parentView)
        userTable.material = options.material
    else
        textView = TextView.new(parentView)
        textView.color = mj.textColor or options.color

        textView.relativePosition = options.relativePosition or ViewPosition(MJPositionCenter, MJPositionCenter)
    end

    textView.font = Font(options.fontName, options.fontSize)

    return textView
end

function uiTextView:setText(view, text)
    local userTable = view.userData
    if userTable.material then
        view:setText(text, userTable.material)
    else
        view.text = text
    end
end

return uiTextView