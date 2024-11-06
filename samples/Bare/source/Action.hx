import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

enum Action
{
	/** Moves the player up, also used to navigate menus */
	@:inputs([FlxKey.UP, FlxKey.W, DPAD_UP, LEFT_STICK_DIGITAL_UP, FlxVirtualPadInputID.UP])
	UP;

	/** Moves the player down, also used to navigate menus */
	@:inputs([FlxKey.DOWN, FlxKey.S, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, FlxVirtualPadInputID.DOWN])
	DOWN;

	/** Moves the player left, also used to navigate menus */
	@:inputs([FlxKey.LEFT, FlxKey.A, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, FlxVirtualPadInputID.LEFT])
	LEFT;

	/** Moves the player right, also used to navigate menus */
	@:inputs([FlxKey.RIGHT, FlxKey.D, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, FlxVirtualPadInputID.RIGHT])
	RIGHT;

	/** Allows for smooth movement */
	@:inputs([LEFT_ANALOG_STICK, Mouse(Motion())]) @:analog(x, y)
	MOVE;

	/** Doesn't do anything, but their values are exposed in the analog visualizer */
	@:inputs([LEFT_TRIGGER])
	@:analog(value)
	TRIGGER_LEFT;

	/** Doesn't do anything, but their values are exposed in the analog visualizer */
	@:inputs([RIGHT_TRIGGER])
	@:analog(value)
	TRIGGER_RIGHT;
}

class Controls extends FlxControls<Action> {}
