package input;

import flixel.FlxG;
import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxControlInputType.FlxKeyInputType.Multi as MultiKey;
import flixel.addons.input.FlxControlInputType.FlxKeyInputType.Arrows as ArrowKeys;
import flixel.addons.input.FlxControlInputType.FlxGamepadInputType.Multi as MultiGPad;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputID as VPad;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputType.Multi as MultiVPad;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputType.Arrows as VPadArrows;
import flixel.input.gamepad.FlxGamepadInputID as GPad;
import flixel.input.keyboard.FlxKey as Key;
import flixel.ui.FlxVirtualPad;

enum Input
{
	// Movement
	@:analog(x, y)
	MOVE;
	
	/** Iterates the various camera styles */
	@:analog(delta)
	STYLE;
	/** Zooms the camera in or out */
	@:analog(delta)
	ZOOM;
	/** Adjusts the camera leading */
	@:analog(delta)
	LEAD;
	/** Adjusts the camera lerp */
	@:analog(delta)
	LERP;
	
	/** Triggers screen shake */
	SHAKE;
}

class PlayerControls extends FlxControls<Input>
{
	function getDefaultMappings():ActionMap<Input>
	{
		return
			[ Input.MOVE  => [ArrowKeys, WASD, DPad, LEFT_ANALOG_STICK, VPadArrows]
			, Input.STYLE => [MultiKey(Y, H), MultiGPad(RIGHT_SHOULDER, LEFT_SHOULDER)]
			, Input.LERP  => [MultiKey(U, J), MultiGPad(RIGHT_TRIGGER, LEFT_TRIGGER)]
			, Input.LEAD  => [MultiKey(I, K), MultiGPad(B, X)]
			, Input.ZOOM  => [MultiKey(O, L), MultiGPad(Y, A)]
			, Input.SHAKE => [Key.M, GPad.RIGHT_STICK_CLICK]
			];
	}
}

/**
 * Simplified virtual pad that takes an Input and returns whether the corresponding button is pressed
 */
abstract VirtualPad(FlxVirtualPad) from FlxVirtualPad to FlxVirtualPad
{
	inline public function new()
	{
		this = new FlxVirtualPad(FULL, NONE);
	}
}