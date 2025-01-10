--[[
	This file attempts to document the built-in features of widget definitions (defs). It has no
	practical use, and shouldn't be instantiated at run-time (though doing so should be harmless).
	For a blank-slate widget, see: blank.lua

	Widget defs are tables that define a single widget tied to an ID value (typically a string).
	There is a chain of __index redirections from widget instances, to their def, to the base
	widget metatable (which has all the built-in methods). A per-def metatable is necessary to
	complete the chain without making the instance its own metatable.

	All widgets are axis aligned rectangles, even if they are invisible and appear formless in UI
	space.

	Most callbacks "bubble up" from the affected widget to each of its ancestors. You can use
	`if self == inst then...` to differentiate between events acting on `self`, or events bubbled up
	from a descendant. Widgets can halt callback-bubbling by returning a truthy value (not false,
	not nil.)

	uiCall_* -> intended to be used with bubbling and trickling mechanisms.
	ui_* -> intended to be called directly.

	---------------------------------------------------------------------------

	The UI Thimble

	"Thimble" is an arbitrary term for which widget currently has focus. The name was chosen because
	it is unlikely to be mistaken for other kinds of focus: OS window focus, in-application frame focus,
	mouse hover + press state, selections within menus, and so on. Generally, the widget which has the
	thimble gets first dibs for keyboard input.

	Lamentably, there are two thimbles: thimble1 and thimble2. The first is for "concrete" widgets,
	while the second is for "ephemeral" components like pop-up menus. The *Top Thimble* is the highest
	one that is currently assigned to a widget:

	+--------------------------------------------+
	| thimble1 | thimble2 | Top Thimble is...    |
	+----------+----------+----------------------+
	|          |          | Neither              |
	|    x     |          | thimble1             |
	|          |    x     | thimble2             |
	|    x     |    x     | thimble2             |
	+--------------------------------------------+

	This system, confusing as it is, allows a concrete widget to know that it is still selected, even if
	key events are temporarily directed to an ephemeral widget.

	---------------------------------------------------------------------------

	A note on "capturing"

	A widget can capture the UI context. When this happens, all prodUI events are passed to the
	widget first, and it has the option to deny the event from being handled by the context. This
	can be used to implement custom behaviors without interference from the context or other
	widgets. For example, the WIMP window-frame resize and drag sensors are implemented with
	capture callbacks.

	While this enables some nice widget behaviors, be warned that capturing is prone to subtle
	input bugs. By default, if a capturing widget does not have a capture callback for an event
	type, then it is always passed on to the main event handler. You may need to capture events
	that have nothing to do with the desired behavior, and handle them appropriately or discard
	them. Consolidating similar capture behavior into shared functions is recommended.

	---------------------------------------------------------------------------

	-> Reserved field prefixes:
	lo_* -> Layout system
	ly_* -> Canvas layering
	sk_* -> Skinner and skin data
	usr_* -> Arbitrary user (application developer) variables
	vp_* -> Viewport data (See: Widget Viewports)

	-> Fields with base widget metatable dummy values:

	tag: (empty string) A string you can use to help locate widgets.

	scr_x, scr_y: Scroll registers, applicable to a widget's children.


	-> Fields with per-instance metatable dummy values:

	id: The identifier value for the widget, as set when the widget def was loaded. Typically a
	string. Do not modify.


	-> Fields set during instance creation (before uiCall_create()):

	x, y: (0, 0) Position of the widget relative to its parent's upper-left corner.
	w, h: (0, 0) Size of the widget body, in pixels. Must be at least zero.
	^ Values set ahead-of-time are preserved.

	context: back-link to the UI Context that this widget exists within. Do not modify.
	parent: back-link to the widget's parent, or false if there is no parent. Do not modify.

	children: table of child widgets and further descendants. This table may be a dummy reference
	if '_no_descendants' was set in the def. Do not modify directly.


	-> Fields set during instance destruction:

	_dead: Identifies widgets that are being removed or have already been removed. Read but do not
	modify.

	* nil: the widget is still part of the context.
	* "dying": the widget is in the process of being removed from the context.
	* "dead": The widget has been removed from the context.


	-> Context-to-widget behavior flags:

	can_have_thimble: When true, widget can obtain the thimble (the UI cursor).

	allow_hover: When true, widget is eligible for the 'current_hover' context state.
	When a truthy value that isn't boolean true (by convention, "just-me"), the widget
	is eligible but not its children (as in, the mouse will click through the children
	and interact with the parent).
	When false, it and all of its descendants are skipped.


	-> Fields applicable to widgets with children:

	hide_children: When truthy, children are not rendered.

	clip_scissor: When true, rendering of children is clipped to the widget's body. When "manual",
	the scissor region is specified in 'clip_scissor_x', 'clip_scissor_y', 'clip_scissor_w', and
	'clip_scissor_h', relative to the top-left of the widget.

	NOTE: don't use math.huge with setScissor or intersectScissor. It will become zero. -2^16 and
	2^17 seem OK.

	clip_hover: When true, mouse hover and click detection against children is clipped to the
	widget's body. When "manual", the clipping region is specified in 'clip_hover_x',
	'clip_hover_y', 'clip_hover_w' and 'clip_hover_h'.

	_no_descendants: When true, upon widget creation, a special shared table is assigned to
	self.children. This table raises an error if self:addChild() is used, or if anything assigns a
	new field via __newindex.
	Use with care: it cannot catch every instance of messing with the table. For example, rawset()
	and table.insert() do not invoke __newindex.

	-> Skin fields:

	skin_id: Used when assigning the widget's skin. Skins allow the appearance of widgets to
	be customized. Not all widgets support skins, and most skins are designed for one or a
	few specific widgets or skinners (implementations).
	Once set, skin_id should not be modified except as part of a skinner/skin replacement action.

	skinner, skin: The skinning implementation and data package, respectively. They are assigned
	to skinned widgets by self:skinSetRefs(). Avoid modifying these tables from the widget instance
	code, as the changes will affect all other widgets with the same skinner / skin.


	-> Widget Viewports:

	Some widgets keep track of rectangular areas known as Viewports. Uses include:

	* Tracking the visible region of scrolling content (the original use case)

	* Separating outer widget components (scroll bars) from the inner content region, to
	  help route mouse-click events

	* Serving as a basic layout boundary for widget content, like labels and simple graphics

	The first viewport's fields are:
		self.vp_x
		self.vp_y
		self.vp_w
		self.vp_h

	The fields of additional viewports include the viewport index. For example, Viewport #2's
	fields are:
		self.vp2_x
		self.vp2_y
		self.vp2_w
		self.vp2_h

	Viewports are typically set up in a reshape() callback by progressively carving out border
	and margin data (stored in the skin), and space for components such as scroll bars.

	Up to eight viewports per widget are permitted by the support code that manages them.
--]]


-- The loader provides the UI context and an arbitrary config table (if provided). The context table
-- includes paths and methods that help with loading and caching ProdUI source files.
local context, def_conf = select("#", ...)


-- Values placed in 'def' will be accessible from instances through the __index metamethod. (We
-- will return def at the end of this source file.)
local def = {}


-- If the widget is skinned, a default 'skin_id' can go here.
--def.skin_id = "foobar"


-- If the widget is skinned, place the built-in skinner implementations here.
-- The default built-in skinner should be named: "default"
--[[
def.skinners = {
	default = {
		-- Installs the skin into the widget.
		-- Called by wid:skinInstall().
		install = function() end,

		-- Removes the skin from the widget.
		-- Called by wid:skinRemove().
		remove = function() end,

		-- Updates the skin state (after a state change to the widget).
		-- Called by wid:skinRefresh()
		refresh = function() end,

		-- Per-frame update callback for the skin.
		-- Called by wid:skinUpdate()
		update = function(dt) end,

		-- Copied to: wid.render
		render = function() end,

		-- Copied to: wid.renderLast
		renderLast = function() end,

		-- Copied to: wid.renderThimble
		renderThimble = function() end,
	},
}
--]]


-- Bubbles when the widget is created via context:addWidget() or widget:addChild().
-- @param inst The newly-created widget instance. May have some fields already set by the caller.
function def:uiCall_create(inst)
	--[[
	Recommendations:
	In your documentation, please list:
	* Mandatory ahead-of-time fields
	* Optional ahead-of-time fields

	Assume that all other fields are assigned defaults, and that the caller must set them after
	successful instance creation.

	If present, `self:userCreate()` is run after this. (It's incredibly redundant as you have
	to pass it in ahead-of-time, but it pairs with `self:userDestroy()`.)
	--]]
end


-- Bubbles when the widget is destroyed.
-- @param inst The destroyed widget instance.
function def:uiCall_destroy(inst)
	--[[
	If present, `self:userDestroy()` is run before this.
	--]]
end


-- Bubbles when the mouse pointer enters a widget's bounding box, and no widget is being pressed.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

end


--- Bubbles when the mouse pointer stops hovering over a widget.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

end


--- Bubbles when the mouse pointer moves over a widget that it is currently hovering over.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerHoverMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- XXX: due to issues with widgets slipping out of the mouse cursor position, this is fired
	-- continously, even if the mouse is idle.
end


--- Called when the context is checking widgets for a mouse hover event. Returning true
--	causes this widget to be selected for the event.
-- @param mx, my Mouse X and Y positions in UI space.
-- @param os_x, os_y Position offsets, such that 'mx + os_x' and 'my + os_y' give the widget's top-left
--	position in UI space.
-- @return true to select this widget, false/nil otherwise.
--[[
function def:ui_evaluateHover(mx, my, os_x, os_y)

end
--]]


--- Called when the context is checking widgets for a mouse press event. Returning true
--	causes this widget to be selected for the event.
-- @param mx, my Mouse X and Y positions in UI space.
-- @param os_x, os_y Position offsets, such that 'mx + os_x' and 'my + os_y' give the widget's top-left
--	position in UI space.
-- @param button The button pressed.
-- @param istouch If this is a touch action.
-- @param presses Number of times this button has been pressed consecutively (for checking double-clicks).
-- @return true to select this widget, false/nil otherwise.
--[[
function def:ui_evaluatePress(mx, my, os_x, os_y, button, istouch, presses)

end
--]]


-- Bubbles when the mouse pointer presses down on the currently hovered widget.
-- @param inst The originating widget instance.
-- @param x 'x' value from love.mousepressed.
-- @param y 'y' value from love.mousepressed.
-- @param button 'button' value from love.mousepressed.
-- @param istouch 'istouch' value from love.mousepressed.
-- @param presses 'presses' value from love.mousepressed.
function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	--[[
	If you want to consider only one pressed button at a time, use:

	if button == self.context.mouse_pressed_button then ...
	--]]
end


-- Bubbles periodically after pressing on a widget and before releasing. Will trigger even if the pointer leaves the pressed widget's area.
-- @param inst The originating widget instance.
-- @param x Mouse X position
-- @param y Mouse Y position
-- @param button Which button is being repeat-pressed
-- @param istouch True if this is a touch input
-- @param reps The number of repetitions up to this point
function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	--[[
	The initial delay and repeat-rate are controlled by the UI Context.

	This is a virtual event, with no equivalent LÖVE callback.

	It will only fire in relation to the button value held in `self.context.mouse_pressed_button`,
	so the check suggested in `uiCall_pointerPress()` is not necessary here (though including it
	would be harmless).
	--]]
end


-- Bubbles when the mouse pointer releases while overlapping a widget it had pressed. Note that this does not trigger if you click on empty space, roll over to a widget, and release.
-- @param inst The originating widget instance.
-- @param x 'x' value from love.mousereleased.
-- @param y 'y' value from love.mousereleased.
-- @param button 'button' value from love.mousereleased.
-- @param istouch 'istouch' value from love.mousereleased.
-- @param presses 'presses' value from love.mousereleased.
function def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)

end


--- Bubbles when the mouse pointer releases in reference to a pressed widget, even if *not* overlapping it.
-- @param inst The originating widget instance.
-- @param x 'x' value from love.mousereleased.
-- @param y 'y' value from love.mousereleased.
-- @param button 'button' value from love.mousereleased.
-- @param istouch 'istouch' value from love.mousereleased.
-- @param presses 'presses' value from love.mousereleased.
function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)

end


-- Bubbles when having pressed on a widget and moving the mouse.
-- @param inst The originating widget instance.
-- @param x Mouse X position
-- @param y Mouse Y position
-- @param dx Mouse X delta from previous position
-- @param dy Mouse Y delta from previous position
function def:uiCall_pointerDrag(inst, x, y, dx, dy)
	-- The actual dragging has to be implemented here.
end


-- Bubbles when the mouse wheel is moved.
function def:uiCall_pointerWheel(x, y)

end


--[[
Drag-Dest events are intended to help with widget-to-widget drag-and-drop actions.

The instance here is a widget that the mouse is overlapping *while* some other
widget is being pressed. Think of the instance as the destination, and the current_pressed
widget as the source.

Behavior notes:

* Source and desination may be the same widget.

* A reference to Source is not provided in the function arguments, but it can be found
  by reading self.context.current_pressed`.

* Source could be destroyed before the drag-and-drop action is completed. Or, the
  general circumstances could have changed. You will unfortunately have to do some
  extra work to ensure that the transaction is valid.
--]]


-- Like uiCall_pointerHoverOn, but issued while a mouse button is pressed.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerDragDestOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

end


--- Like uiCall_pointerHoverOff, but issued while a mouse button is pressed.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerDragDestOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

end


--- Like uiCall_pointerHoverMove, but issued while a mouse button is pressed.
-- @param inst The originating widget instance.
-- @param mouse_x Mouse X position, relative to the LÖVE application window.
-- @param mouse_y Mouse Y position, relative to the LÖVE application window.
-- @param mouse_dx Relative mouse X delta from previous position, if applicable.
-- @param mouse_dy Relative mouse Y delta from previous position, if applicable.
function def:uiCall_pointerDragDestMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- XXX: like uiCall_pointerHoverMove, this is fired continuously, even if the
	-- mouse is idle.
end


-- Like uiCall_pointerRelease, but applies to a widget that the mouse is over while the "pressing" state is active, potentially on another widget.
-- @param inst The originating widget instance.
-- @param x 'x' value from love.mousereleased.
-- @param y 'y' value from love.mousereleased.
-- @param button 'button' value from love.mousereleased.
-- @param istouch 'istouch' value from love.mousereleased.
-- @param presses 'presses' value from love.mousereleased.
function def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)

end


-- Bubbles when a widget takes thimble1.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.
function def:uiCall_thimble1Take(inst, a, b, c, d)

end


-- Bubbles when a widget takes thimble2.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget:thimble2Take(). Usage depends on the implementation.
function def:uiCall_thimble2Take(inst, a, b, c, d)

end


-- Bubbles when a widget releases thimble1.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget:thimble1Release(). Usage depends on the implementation.
function def:uiCall_thimble1Release(inst, a, b, c, d)

end


-- Bubbles when a widget releases thimble2.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget:thimble2Release(). Usage depends on the implementation.
function def:uiCall_thimble2Release(inst, a, b, c, d)

end


-- Bubbles when a widget gains the top thimble.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget methods. Usage depends on the implementation.
function def:uiCall_thimbleTopTake(inst, a, b, c, d)

end


-- Bubbles when a widget loses the top thimble.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget methods. Usage depends on the implementation.
function def:uiCall_thimbleTopRelease(inst, a, b, c, d)

end


-- Bubbles in thimble2 when thimble1 changes.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget methods. Usage depends on the implementation.
function def:uiCall_thimble1Changed(inst, a, b, c, d)

end


-- Bubbles in thimble1 when thimble2 changes.
-- @param inst The originating widget instance.
-- @param a, b, c, d Generic arguments which are supplied through widget methods. Usage depends on the implementation.
function def:uiCall_thimble2Changed(inst, a, b, c, d)

end


-- Bubbles when the user presses enter or space while this widget has the thimble. The enter key fires repeatedly,
--	while space only fires once per key-down.
-- @param inst The originating widget instance.
function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)

end


-- Bubbles when the user presses the Application key or Shift+F10 while this widget has the thimble. Does not
--	fire repeatedly.
-- @param inst The originating widget instance.
function def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)

end


-- Bubbles when a love.keypressed() event reaches the widget.
function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

end

-- Bubbles when a love.keyreleased() event reaches the widget.
function def:uiCall_keyReleased(inst, key, scancode)

end


-- Bubbles when a love.textinput() event reaches the widget. These are independent of keyboard down/up events, and text input must be enabled in LÖVE. The context checks the UTF-8 encoding before invoking the event.
function def:uiCall_textInput(inst, text)

end



--- Runs when the widget captures the context.
-- @param inst The originating widget instance.
function def:uiCall_capture(inst)

end


--- Runs when the widget is no longer capturing the context.
function def:uiCall_uncapture(inst)

end


--- Runs on the start of every frame when the widget has captured the UI Context.
-- @param dt The current frame's delta time.
-- @return non-truthy to prevent other widgets from updating on this frame.
function def:uiCall_captureTick(dt)
	return true
end


--[[
When a widget has captured the context/focus, the following callbacks, if present, are executed as
prodUI events occur. The capturing widget gets first dibs on the event, and can deny the main event
handler from acting on the event by returning a truthy value.

Some of these don't make much sense -- why would a capturing widget need to hijack the window
resize event? -- but are included for the sake of completeness.

function def:uiCap_windowResize(w, h) -- (love.resize)

function def:uiCap_keyPressed(key, scancode, isrepeat)
function def:uiCap_keyReleased(key, scancode)

function def:uiCap_textEdited(text, start, length)
function def:uiCap_textInput(text)

function def:uiCap_mouseFocus(focus)
function def:uiCap_wheelMoved(x, y)

function def:uiCap_mouseMoved(x, y, dx, dy, istouch)
^ Warning: mouse hover state is not updated automatically when this is in effect.

function def:uiCap_mousePressed(x, y, button, istouch, presses)
function def:uiCap_mouseReleased(x, y, button, istouch, presses)

function def:uiCap_virtualMouseRepeat(x, y, button, istouch, reps)

function def:uiCap_windowFocus(focus)
function def:uiCap_mouseFocus(focus)

function def:uiCap_windowVisible(visible)

function def:uiCap_joystickAdded(joystick)
function def:uiCap_joystickRemoved(joystick)
function def:uiCap_joystickPressed(joystick, button)
function def:uiCap_joystickReleased(joystick, button)
function def:uiCap_joystickAxis(joystick, axis, value)
function def:uiCap_joystickHat(joystick, hat, direction)

function def:uiCap_gamepadPressed(joystick, button)
function def:uiCap_gamepadReleased(joystick, button)
function def:uiCap_gamepadAxis(joystick, axis, value)
--]]


--- Runs when self:reshape() or self:reshapeChildren() are called. Be careful about calling wid:reshape() on children within uiCall_reshape(), since wid:reshape() itself can be configured to be called on descendants recursively.
-- @param recursive True if reshape() was called with the recursive argument.
-- @return Truthy value to halt reshaping of descendants in widget reshape methods.
function def:uiCall_reshape(recursive)
	--[[
		NOTE: Reshaping is intended to modify a widget's content (children, minor visual details etc.), and
		not its current dimensions and position within its parent. There are some exceptions:
		1) It might be sensible to resize the tree root in uiCall_reshape() because it does not have a parent.
		2) You have free-floating window frames which must be clamped to their parent container, and their
		positions and sizes do not affect their siblings.
	--]]
end


--- Runs when self:resize() is called. This can be used to prompt a widget to update its dimensions without having to know details about its internals.
function def:uiCall_resize()

end


--- Draws the widget. The graphics state is already translated so that 0,0 is the top-left corner of the widget.
-- @param os_x X offset in screen pixels. You don't usually need this unless you are changing the current scissor box.
-- @param os_y Y offset in screen pixels.
--[[
function def:render(os_x, os_y)

end
--]]


--- An optional draw method that is called after a widget's children are handled.
-- @param os_x X offset in screen pixels. You don't usually need this unless you are changing the current scissor box.
-- @param os_y Y offset in screen pixels.
--[[
function def:renderLast(os_x, os_y)

end
--]]


--- Optional draw method for the thimble (represents the current highlighted widget / control object). Note that this can only trigger for widgets which are configured to "host" the thimble.
--[[
function def:renderThimble()

end
--]]


--- This is run in prodUI.love_update(), starting with context.tree and traversing depth-first. Note that of the top-level instances, only widgets in the current root are updated.
-- @param dt The delta time from love.update().
-- @return truthy value to explicitly prevent updating the widget's children. (If uiCall_update doesn't exist in the widget, children will be updated.)
function def:uiCall_update(dt)
	--[[
	There are many limitations in effect when the context is locked for updating. Anything
	that is likely to mess up tree traversal (remove or reorder widgets; change tree root) will raise
	an error. You can defer these actions to after the update loop using context:appendAsyncAction().

	Widgets may or may not have a built-in `uiCall_update` method. If not, you can supply your own.
	You can also assign `self:userUpdate(dt)`, which is run before `uiCall_update`.

	`uiCall_update` only fires for the current tree root and its descendants. Other top-level instances
	that are not the root are not updated.
	--]]
end


--- Runs on the tree root as a result of the love.focus() event.
-- @param focus True if the window has focus, false if not.
function def:uiCall_windowFocus(focus)

end


--- Runs on the tree root as a result of the love.mousefocus() event.
-- @param focus True if the mouse is in the window, false if not (with some exceptions when click-dragging out of frame).
function def:uiCall_mouseFocus(focus)

end


--- Runs on the tree root as a result of love.visible().
function def:uiCall_windowVisible(visible)

end


--- Runs on the tree root as a result of the love.resize() event.
-- @param w The new width of the window screen.
-- @param h The new height of the window screen.
function def:uiCall_windowResize(w, h)

end


--- Runs on the tree root as a result of love.joystickadded().
-- @param joystick The joystick that was added.
function def:uiCall_joystickAdded(joystick)

end


--- Runs on the tree root as a result of love.joystickremoved().
-- @param joystick The joystick that was removed.
function def:uiCall_joystickRemoved(joystick)

end


--- Bubbles when getting a button-down event from love.joystickpressed().
-- @param joystick The joystick associated with the button press.
-- @param button Numeric index of the pressed button.
function def:uiCall_joystickPressed(inst, joystick, button)

end


--- Bubbles when getting a button-up event from love.joystickreleased().
-- @param joystick The joystick associated with the button release event.
-- @param button Numeric index of the pressed button.
function def:uiCall_joystickPressed(inst, joystick, button)

end


--- Bubbles when getting an axis update event from love.joystickaxis().
-- @param joystick The joystick associated with the axis motion event.
-- @param axis Numeric index of the moved axis.
-- @param value The numeric value of the axis, from -1.0 to 1.0.
function def:uiCall_joystickAxis(inst, joystick, axis, value)

end


--- Bubbles when getting a hat switch event from love.joystickhat().
-- @param joystick The joystick associated with the hat event.
-- @param hat Numeric index of the moving hat.
-- @param direction String enum representing the current position of the hat.
function def:uiCall_joystickHat(inst, joystick, hat, direction)

end


--- --- Bubbles when getting a button-down event from love.gamepadpressed().
-- @param joystick The joystick associated with the gamepad button press event.
-- @param button String enum of the gamepad button pressed.
function def:uiCall_gamepadPressed(inst, joystick, button)

end


--- Bubbles when getting a button-up event from love.gamepadreleased().
-- @param joystick The joystick associated with the gamepad button release event.
-- @param button String enum of the gamepad button released.
function def:uiCall_gamepadReleased(inst, joystick, button)

end


--- Bubbles when getting a gamepad axis event from love.gamepadaxis().
-- @param joystick The joystick associated with the moving gamepad axis.
-- @param axis String enum of the gamepad axis moved.
-- @param value The value of the axis, from -1.0 to 1.0.
function def:uiCall_gamepadAxis(inst, joystick, axis, value)

end


return def
