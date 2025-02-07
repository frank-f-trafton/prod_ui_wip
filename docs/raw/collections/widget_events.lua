return {
	type = "collection",
	title = "Widget Events",
	id = "widget_event",
	schema = {
		main = {
			["#"] = {
				name = "string",
				propagation_method = "string",
				event_origin = "string",
				description = "string",
				signature = "string",
				parameters = {
					["#"] = {
						name = "string",
						type = "string",
						description = "string"
					}
				},
				returns = "nil|string",
				example = "nil|string",
				notes = "nil|string"
			}
		}
	},
	main = {
		{
			name = "uiCall_gamepadReleased",
			propagation_method = "TODO",
			event_origin = "[love.gamepadreleased](https://love2d.org/wiki/love.gamepadreleased)",
			description = "A held gamepad button was released.",
			signature = "def:uiCall_gamepadReleased(inst, joystick, button)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "button",
					type = "love:GamepadButton",
					description = "The ID of the released gamepad button.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_gamepadAxis",
			propagation_method = "TODO",
			event_origin = "[love.gamepadaxis](https://love2d.org/wiki/love.gamepadaxis)",
			description = "A gamepad axis moved.",
			signature = "def:uiCall_gamepadAxis(inst, joystick, axis, value)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "value",
					type = "number",
					description = "The value of the axis, from -1.0 to 1.0.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_gamepadPressed",
			propagation_method = "TODO",
			event_origin = "[love.gamepadpressed](https://love2d.org/wiki/love.gamepadpressed)",
			description = "A gamepad button was pressed.",
			signature = "def:uiCall_gamepadPressed(inst, joystick, button)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "button",
					type = "love:GamepadButton",
					description = "The button ID.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_joystickHat",
			propagation_method = "TODO",
			event_origin = "[love.joystickhat](https://love2d.org/wiki/love.joystickhat)",
			description = "A joystick POV hat moved.",
			signature = "def:uiCall_joystickHat(inst, joystick, hat, direction)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "hat",
					type = "number",
					description = "The hat index.",
				}, {
					name = "direction",
					type = "love:JoystickHat",
					description = "The hat direction.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_joystickAxis",
			propagation_method = "TODO",
			event_origin = "[love.joystickaxis](https://love2d.org/wiki/love.joystickaxis)",
			description = "A joystick axis moved.",
			signature = "def:uiCall_joystickAxis(inst, joystick, axis, value)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "axis",
					type = "number",
					description = "The axis index.",
				}, {
					name = "value",
					type = "number",
					description = "The axis value.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_joystickReleased",
			propagation_method = "TODO",
			event_origin = "[love.joystickreleased](https://love2d.org/wiki/love.joystickreleased)",
			description = "A joystick button was released.",
			signature = "def:uiCall_joystickReleased(inst, joystick, button)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "button",
					type = "number",
					description = "The button index."
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_joystickPressed",
			propagation_method = "TODO",
			event_origin = "[love.joystickpressed](https://love2d.org/wiki/love.joystickpressed)",
			description = "A joystick button was pressed.",
			signature = "def:uiCall_joystickPressed(inst, joystick, button)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				}, {
					name = "button",
					type = "number",
					description = "The button index."
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_windowVisible",
			propagation_method = "sent to root",
			event_origin = "[love.visible](https://love2d.org/wiki/love.visible)",
			description = "The application window's visibility changed.",
			signature = "def:uiCall_windowVisible(visible)",
			parameters = {
				{
					name = "visible",
					type = "boolean",
					description = "True if the window is visible, false if not.",
				},
			},
			returns = "Nothing.",
		},

		{
			name = "uiCall_windowResize",
			propagation_method = "sent to root",
			event_origin = "[love.resize](https://love2d.org/wiki/love.resize)",
			description = "The application window was resized.",
			signature = "def:uiCall_windowResize(w, h)",
			parameters = {
				{
					name = "w, h",
					type = "number",
					description = "The new window width and height.",
				},
			},
			returns = "Nothing.",
		},

		{
			name = "uiCall_joystickAdded",
			propagation_method = "sent to root",
			event_origin = "[love.joystickadded](https://love2d.org/wiki/love.joystickadded)",
			description = "A joystick was connected.",
			signature = "def:uiCall_joystickAdded(joystick)",
			parameters = {
				{
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				},
			},
			returns = "Nothing.",
		},

		{
			name = "uiCall_joystickRemoved",
			propagation_method = "sent to root",
			event_origin = "[love.joystickremoved](https://love2d.org/wiki/love.joystickremoved)",
			description = "A joystick was disconnected.",
			signature = "def:uiCall_joystickRemoved(joystick)",
			parameters = {
				{
					name = "joystick",
					type = "love:Joystick",
					description = "The joystick associated with the event.",
				},
			},
			returns = "Nothing.",
		},

		{
			name = "uiCall_update",
			propagation_method = "broadcast down",
			event_origin = "[love.update](https://love2d.org/wiki/love.update)",
			description = "A per-frame update callback for widgets.",
			signature = "def:uiCall_update(dt)",
			parameters = {
				{
					name = "dt",
					type = "number",
					description = "This frame's delta time.",
				}
			},
			returns = "True to halt event propagation to this widget's children.",
			notes = [==[
				This is run in prodUI.love_update(), starting with context.root and traversing its children depth-first.

                Return true to explicitly prevent updating a widget's children. (If uiCall_update doesn't exist in the widget, children will be updated.)

                There are many limitations in effect when the context is locked for updating. Anything that is likely to mess up tree traversal (remove or reorder widgets; change tree root) will raise an error. You can defer these actions to after the update loop using context:appendAsyncAction().

                Widgets may or may not have a built-in 'uiCall_update' method. If not, you can supply your own. You can also assign 'self:userUpdate(dt)', which is run before 'uiCall_update'.

                'uiCall_update' only fires for the current tree root and its descendants. Other top-level instances that are not the root are not updated.
			]==],
		},

		{
			name = "uiCall_windowFocus",
			propagation_method = "sent to root",
			event_origin = "[love.focus](https://love2d.org/wiki/love.focus)",
			description = "The application window focus changed.",
			signature = "def:uiCall_windowFocus(focus)",
			parameters = {
				{
					name = "focus",
					type = "boolean",
					description = "True if the window has focus, false if not.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_mouseFocus",
			propagation_method = "sent to root",
			event_origin = "[love.mousefocus](https://love2d.org/wiki/love.mousefocus)",
			description = "The application window's mouse focus changed.",
			signature = "def:uiCall_mouseFocus(focus)",
			parameters = {
				{
					name = "focus",
					type = "boolean",
					description = "True if the window has mouse focus, false if not.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_reshape",
			propagation_method = "broadcast down",
			event_origin = "widget:reshape()",
			description = "A widget called self:reshape() or self:reshapeChildren().",
			signature = "def:uiCall_reshape(recursive)",
			parameters = {
				{
					name = "recursive",
					type = "boolean",
					description = "True if reshape() was called with the recursive argument.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Be careful about calling wid:reshape() on children within uiCall_reshape(), since wid:reshape() itself can be configured to be called on descendants recursively.

                Reshaping is intended to modify a widget's content (children, minor visual details etc.), and not its current dimensions and position within its parent. There are some exceptions:

                1) It might be sensible to resize the tree root in uiCall_reshape() because it does not have a parent.

                2) You have free-floating window frames which must be clamped to their parent container, and their positions and sizes do not affect their siblings.
			]==],
		},

		{
			name = "uiCall_resize",
			propagation_method = "TODO",
			event_origin = "widget:resize()",
			description = "TODO",
			signature = "TODO",
			parameters = {},
			returns = "TODO",
		},

		{
			name = "uiCall_initialize",
			propagation_method = "sent to widget",
			event_origin = "widget:initialize()",
			description = "A new widget is being initialized.",
			signature = "def:uiCall_initialize(...)",
			parameters = {
				{
					name = "...",
					type = "any",
					description = "Arguments for the widget setup callback.",
				},
			},
			returns = "Nothing.",
			notes = [==[
                In your documentation, please list:

                * Mandatory ahead-of-time fields
                * Optional ahead-of-time fields

                Assume that all other fields are assigned defaults, and that the caller must set them after successful instance creation.

                If present, <code lang="lua">self:userInitialize()</code> is run after this. (It's incredibly redundant as you have to pass it in ahead of time, but it pairs with <code lang="lua">self:userDestroy()</code>.)
			]==],
		},

		{
			name = "uiCall_destroy",
			propagation_method = "bubbleEvent",
			event_origin = "widget:remove()",
			description = "A widget was removed from the context.",
			signature = "def:uiCall_destroy(inst)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                If present, `widget:userDestroy()` is run before this.
			]==],
		},

		{
			name = "uiCall_pointerHoverOn",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse pointer entered a widget's bounding rectangle.",
			signature = "def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Hover events are postponed while any mouse button is held.
			]==],
		},

		{
			name = "uiCall_pointerHoverOff",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed)[love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse pointer left a widget's bounding rectangle.",
			signature = "def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				}
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Hover events are postponed while any mouse button is held.
			]==],
		},

		{
			name = "uiCall_pointerHover",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse pointer is resting or moving over a widget.",
			signature = "def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				}
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_pointerPress",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousepressed](https://love2d.org/wiki/love.mousepressed)",
			description = "The mouse cursor pressed down on a widget.",
			signature = "def:uiCall_pointerPress(inst, x, y, button, istouch, presses)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse cursor position.",
				}, {
					name = "button",
					type = "number",
					description = "The index of the the pressed mouse button.",
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event."
				}, {
					name = "presses",
					type = "number",
					description = "The number of consecutive presses, as determined by love.mousepressed()."
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                This event does not trigger if no widget was clicked (ie the root disables mouse-hover, which in turn prevents clicking on it and all descendants).

                If you want to consider only one pressed button at a time, use:

                `if button == self.context.mouse_pressed_button then ...`
			]==],
		},

		{
			name = "uiCall_pointerPressRepeat",
			propagation_method = "cycleEvent",
			event_origin = "[love.update](https://love2d.org/wiki/love.update)",
			description = "Called periodically after the the mouse has remained pressed on a widget for some time.",
			signature = "def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse cursor position.",
				}, {
					name = "button",
					type = "number",
					description = "The index of the the pressed mouse button.",
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event.",
				}, {
					name = "reps",
					type = "number",
					description = "The number of consecutive repeat events emitted up to this point, starting at 1.",
				}
			},
			returns = "True to halt event propagation.",
			notes = [==[
                This event will emit even if the pointer leaves the pressed widget's area.

                The initial delay and repeat-rate are controlled by the UI Context.

                This is a virtual event, with no equivalent LÖVE callback.

                It will only fire in relation to the button value held in `self.context.mouse_pressed_button`, so the check suggested in `uiCall_pointerPress()` is not necessary here (though including it would be harmless).
			]==],
		},

		{
			name = "uiCall_pointerRelease",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousereleased](https://love2d.org/wiki/love.mousereleased)",
			description = "The mouse cursor stopped pressing on a widget, and the cursor was within the widget's bounds.",
			signature = "def:uiCall_pointerRelease(inst, x, y, button, istouch, presses)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse cursor position.",
				}, {
					name = "button",
					type = "number",
					description = "The index of the the pressed mouse button.",
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event."
				}, {
					name = "presses",
					type = "number",
					description = "The number of consecutive presses, as determined by love.mousepressed()."
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                This event only emits if the mouse cursor is over the widget that is designated as "currently-pressed" by the context.
			]==],
		},

		{
			name = "uiCall_pointerUnpress",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousereleased](https://love2d.org/wiki/love.mousereleased)",
			description = "The mouse stopped pressing on a widget.",
			signature = "def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse cursor position.",
				}, {
					name = "button",
					type = "number",
					description = "The index of the the pressed mouse button.",
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event."
				}, {
					name = "presses",
					type = "number",
					description = "The number of consecutive presses, as determined by love.mousepressed()."
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                This event will emit even if the mouse cursor has left the currently-pressed widget.
			]==],
		},

		{
			name = "uiCall_pointerDrag",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse cursor is pressing on this widget.",
			signature = "def:uiCall_pointerDrag(inst, x, y, dx, dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse position.",
				}, {
					name = "dx, dy",
					type = "number",
					description = "The mouse position's delta from the previous frame, if applicable.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Called per-frame.
			]==],
		},

		{
			name = "uiCall_pointerWheel",
			propagation_method = "cycleEvent",
			event_origin = "[love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse wheel moved.",
			signature = "def:uiCall_pointerWheel(x, y)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The wheel's movement vector.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_pointerDragDestOn",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse cursor, while pressing, dragged onto this widget.",
			signature = "def:uiCall_pointerDragDestOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Drag-Dest events are intended to help with widget-to-widget drag-and-drop actions.

                The instance here is a widget that the mouse is overlapping *while* some other widget is being pressed. Think of the instance as the destination, and the current_pressed widget as the source.

                Behavior notes:

                * Source and destination can be the same widget.

                * A reference to Source is not provided in the function arguments, but it can be found by reading self.context.current_pressed.

                * Source could be destroyed before the drag-and-drop action is completed. Or, the circumstances could have changed. Unfortunately, you will have to do some extra work to ensure that the transaction is valid.
			]==],
		},

		{
			name = "uiCall_pointerDragDestOff",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse cursor, while pressing, moved off of this widget.",
			signature = "def:uiCall_pointerDragDestOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_pointerDragDestMove",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse, while pressing, is currently over this widget.",
			signature = "def:uiCall_pointerDragDestMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "mouse_x, mouse_y",
					type = "number",
					description = "Mouse cursor position, relative to the application window.",
				}, {
					name = "mouse_dx, mouse_dy",
					type = "number",
					description = "Relative mouse delta from its last position, if applicable.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Like uiCall_pointerHover, this is per-frame, regardless of mouse movement. It should probably be renamed.
			]==],
		},

		{
			name = "uiCall_pointerDragDestRelease",
			propagation_method = "cycleEvent",
			event_origin = "[love.mousemoved](https://love2d.org/wiki/love.mousemoved), [love.mousepressed](https://love2d.org/wiki/love.mousepressed), [love.mousereleased](https://love2d.org/wiki/love.mousereleased), [love.update](https://love2d.org/wiki/love.update), [love.wheelmoved](https://love2d.org/wiki/love.wheelmoved)",
			description = "The mouse cursor released a button while over this widget.",
			signature = "def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "x, y",
					type = "number",
					description = "The mouse cursor position.",
				}, {
					name = "button",
					type = "number",
					description = "The index of the the pressed mouse button.",
				}, {
					name = "istouch",
					type = "boolean",
					description = "True if this is a touch event.",
				}, {
					name = "presses",
					type = "number",
					description = "The number of consecutive presses, as determined by love.mousepressed().",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimble1Take",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble1()",
			description = "A widget took thimble1.",
			signature = "def:uiCall_thimble1Take(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation."
		},

		{
			name = "uiCall_thimble2Take",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble2()",
			description = "A widget took thimble2.",
			signature = "def:uiCall_thimble1Take(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimble1Release",
			propagation_method = "cycleEvent",
			event_origin = "widget:releaseThimble1()",
			description = "A widget released or lost thimble1.",
			signature = "def:uiCall_thimble1Release(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimble2Release",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble2(), widget:releaseThimble2()",
			description = "A widget released thimble2.",
			signature = "def:uiCall_thimble2Release(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimbleTopTake",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble1(), widget:takeThimble2(), widget:releaseThimble2()",
			description = "A widget got the top thimble.",
			signature = "def:uiCall_thimbleTopTake(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimbleTopRelease",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble2(), widget:releaseThimble1(), widget:releaseThimble2()",
			description = "A widget lost the top thimble.",
			signature = "def:uiCall_thimbleTopRelease(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimble1Changed",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble1(), widget:releaseThimble1()",
			description = "Emitted to the holder of thimble2 when thimble1 changes.",
			signature = "def:uiCall_thimble1Changed(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimble2Changed",
			propagation_method = "cycleEvent",
			event_origin = "widget:takeThimble2(), widget:releaseThimble2()",
			description = "Emitted to the holder of thimble1 when thimble2 changes.",
			signature = "def:uiCall_thimble2Changed(inst, a, b, c, d)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "a, b, c, d",
					type = "any",
					description = "Generic arguments which are supplied through widget:thimble1Take(). Usage depends on the implementation.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_thimbleAction",
			propagation_method = "cycleEvent",
			event_origin = "WIMP Root",
			description = "The user pressed enter (return) or space while this widget had the thimble.",
			signature = "def:uiCall_thimbleAction(inst, key, scancode, isrepeat)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "key",
					type = "string",
					description = "The key code.",
				}, {
					name = "scancode",
					type = "string",
					description = "The keyboard scancode (maps to the classic US QWERTY keyboard layout).",
				}, {
					name = "isrepeat",
					type = "boolean",
					description = "True if this is a repeat key event.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                The enter key fires repeatedly, while space only fires once per key press.
			]==],
		},

		{
			name = "uiCall_thimbleAction2",
			propagation_method = "cycleEvent",
			event_origin = "WIMP Root",
			description = "The user pressed the Application key or Shift+F10 while a widget had the thimble.",
			signature = "def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "key",
					type = "string",
					description = "The key code.",
				}, {
					name = "scancode",
					type = "string",
					description = "The keyboard scancode (maps to the classic US QWERTY keyboard layout).",
				}, {
					name = "isrepeat",
					type = "boolean",
					description = "True if this is a repeat key event.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Does not fire repeatedly.
			]==],
		},

		{
			name = "uiCall_keyPressed",
			propagation_method = "cycleEvent",
			event_origin = "[love.keypressed](https://love2d.org/wiki/love.keypressed)",
			description = "The user pressed a key while this widget had the thimble.",
			signature = "def:uiCall_keyPressed(inst, key, scancode, isrepeat)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "key",
					type = "string",
					description = "The key code.",
				}, {
					name = "scancode",
					type = "string",
					description = "The keyboard scancode (maps to the classic US QWERTY keyboard layout).",
				}, {
					name = "isrepeat",
					type = "boolean",
					description = "True if this is a repeat key event.",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_keyReleased",
			propagation_method = "cycleEvent",
			event_origin = "[love.keyreleased](https://love2d.org/wiki/love.keyreleased)",
			description = "The user released a key while this widget had the thimble.",
			signature = "def:uiCall_keyReleased(inst, key, scancode)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "key",
					type = "string",
					description = "The key code.",
				}, {
					name = "scancode",
					type = "string",
					description = "The keyboard scancode (maps to the classic US QWERTY keyboard layout).",
				},
			},
			returns = "True to halt event propagation.",
		},

		{
			name = "uiCall_textInput",
			propagation_method = "cycleEvent",
			event_origin = "[love.textinput](https://love2d.org/wiki/love.textinput)",
			description = "The user inputted text.",
			signature = "def:uiCall_textInput(inst, text)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "text",
					type = "string",
					description = "The text.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                These events are independent of keyboard key down and key up events.

                LÖVE text input must be enabled.

                The context checks the UTF-8 encoding of the text before invoking the event.
			]==],
		},

		{
			name = "uiCall_fileDropped",
			propagation_method = "cycleEvent",
			event_origin = "[love.filedropped](https://love2d.org/wiki/love.filedropped)",
			description = "The user dropped a file onto the application window.",
			signature = "def:uiCall_fileDropped(inst, file)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "file",
					type = "love:DroppedFile",
					description = "The file object.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Refer to the [LÖVE Wiki](https://love2d.org/wiki/love.filedropped) for information on how to work with the file argument.
			]==],
		},

		{
			name = "uiCall_directoryDropped",
			propagation_method = "cycleEvent",
			event_origin = "[love.directorydropped](https://love2d.org/wiki/love.directorydropped)",
			description = "The user dropped a directory onto the application window.",
			signature = "def:uiCall_directoryDropped(inst, path)",
			parameters = {
				{
					name = "inst",
					type = "ui:Widget",
					description = "The target widget instance.",
				}, {
					name = "path",
					type = "string",
					description = "The directory path.",
				},
			},
			returns = "True to halt event propagation.",
			notes = [==[
                Refer to the [LÖVE Wiki](https://love2d.org/wiki/love.directorydropped) for information on how to work with the path argument.
			]==],
		},

		{
			name = "uiCall_capture",
			propagation_method = "sendEvent",
			event_origin = "widget:captureFocus()",
			description = "A widget started capturing events from the context.",
			signature = "def:uiCall_capture(inst)",
			parameters = {},
			returns = "Nothing."
		},

		{
			name = "uiCall_uncapture",
			propagation_method = "sendEvent",
			event_origin = "widget:captureFocus(), widget:uncaptureFocus()",
			description = "A widget stopped capturing events from the context.",
			signature = "def:uiCall_uncapture(inst)",
			parameters = {},
			returns = "Nothing."
		},

		{
			name = "uiCall_captureTick",
			propagation_method = "sendEvent",
			event_origin = "[love.update](https://love2d.org/wiki/love.update)",
			description = "Runs on the start of every frame when the widget is capturing events from the context.",
			signature = "def:uiCall_captureTick(dt)",
			parameters = {
				{
					name = "dt",
					type = "number",
					description = "This frame's delta time (from love.update()).",
				},
			},
			returns = "False to prevent other widgets from updating on this frame.",
		},
	}
}


--[====[
<!-- TODO: format later


When a widget has captured the context/focus, the following callbacks, if present, are executed as
prodUI events occur. The capturing widget gets first dibs on the event, and can deny the main event
handler from acting on the event by returning a truthy value.

Some of these don't make much sense — why would a capturing widget need to hijack the window
resize event? — but are included for the sake of completeness.

function def:uiCap_windowResize(w, h) — (love.resize)

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
-->
--]====]
