package input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxControlInputType.FlxMouseInputType.Motion as MouseMove;
import flixel.addons.input.FlxControlInputType.FlxMouseInputType.Motion as MouseDrag;
import flixel.addons.input.FlxControlInputType.FlxKeyInputType.Multi as MultiKey;
import flixel.addons.input.FlxControlInputType.FlxKeyInputType.Arrows as ArrowKeys;
import flixel.addons.input.FlxControlInputType.FlxGamepadInputType.Multi as MultiPad;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputType.Multi as MultiVPad;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputType.Arrows as VPadArrows;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputID as VPad;
import flixel.input.gamepad.FlxGamepadInputID as GPad;
import flixel.input.keyboard.FlxKey as Key;

/**
 * A list of actions the user can perform via inputs.
 * `@:analog` actions expect inputs like gamepad triggers, joysticks, and mice.
 * `@:inputs` determines the default inputs mapped to this action (can be swapped at runtime)
 */
enum Action2
{
    // @:inputs([Key.W, GPad.DPAD_UP   , RIGHT_STICK_DIGITAL_UP   ]) U;
    // @:inputs([Key.S, GPad.DPAD_DOWN , RIGHT_STICK_DIGITAL_DOWN ]) D;
    // @:inputs([Key.A, GPad.DPAD_LEFT , RIGHT_STICK_DIGITAL_LEFT ]) L;
    // @:inputs([Key.D, GPad.DPAD_RIGHT, RIGHT_STICK_DIGITAL_RIGHT]) R;
    
    // @:inputs([ArrowKeys, Face, LEFT_ANALOG_STICK])
    @:inputs([ArrowKeys, Face, DPad, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK])
    @:analog(x, y) MOVE;
}

class Controls2 extends FlxControls<Action2> {}
