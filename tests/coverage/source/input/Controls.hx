package input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxControlInputType.FlxMouseInputType.Motion as MouseMove;
import flixel.addons.input.FlxControlInputType.FlxMouseInputType.Drag as MouseDrag;
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
enum Action
{
    @:inputs([Key.W, GPad.Y, RIGHT_STICK_DIGITAL_UP   , VPad.Y]) YELLOW;
    @:inputs([Key.S, GPad.A, RIGHT_STICK_DIGITAL_DOWN , VPad.A]) GREEN;
    @:inputs([Key.A, GPad.X, RIGHT_STICK_DIGITAL_LEFT , VPad.X]) BLUE;
    @:inputs([Key.D, GPad.B, RIGHT_STICK_DIGITAL_RIGHT, VPad.B]) RED;
    
    // @:inputs([ArrowKeys, DPad, VPadArrows, LEFT_ANALOG_STICK, MouseMove(BOTH, 0.1)])
    @:inputs([ArrowKeys, DPad, VPadArrows, LEFT_ANALOG_STICK, VPad.STICK])
    // @:inputs([ArrowKeys, Face, DPad, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK])
    @:analog(x, y) MOVE;
}

class Controls extends FlxControls<Action> {}
