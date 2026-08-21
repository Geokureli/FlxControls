package flixel.addons.input;

import flixel.addons.input.FlxControlInputType.FlxControlInputTypeRaw.Gamepad as GamepadControl;
import flixel.addons.input.FlxControlInputType.FlxControlInputTypeRaw.Keyboard as KeyboardControl;
import flixel.addons.input.FlxControlInputType.FlxControlInputTypeRaw.Mouse as MouseControl;
import flixel.addons.input.FlxControlInputType.FlxControlInputTypeRaw.VirtualPad as VirtualPadControl;
import flixel.addons.input.FlxControlInputType.FlxGamepadInputType;
import flixel.addons.input.FlxControlInputType.FlxMouseInputType;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadInputID.LEFT_STICK_DIGITAL_UP as LS_UP;
import flixel.input.gamepad.FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN as LS_DOWN;
import flixel.input.gamepad.FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT as LS_LEFT;
import flixel.input.gamepad.FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT as LS_RIGHT;
import flixel.input.gamepad.FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP as RS_UP;
import flixel.input.gamepad.FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN as RS_DOWN;
import flixel.input.gamepad.FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT as RS_LEFT;
import flixel.input.gamepad.FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT as RS_RIGHT;
import flixel.input.gamepad.FlxGamepadMappedInput;
import flixel.input.keyboard.FlxKey;

/**
 * A device specific id for every input that can be attached to an action. For gamepads it will use
 * identifiers such as `WII_REMOTE(A)` or `PS4(SQUARE)`. For keyboard, the button label is returned.
 * for "Multi button" inputs (like analog WASD), an array is returned.
 */
enum FlxControlMappedInput
{
    /** A button or buttons on a keyboard */
    Keyboard(type:FlxMappedInputType<String>);
    /** Any button, buttons, analog stick or trigger on a gamepad */
    Gamepad(type:FlxMappedInputType<FlxGamepadMappedInput>);
    /** Any button, or position/movement from the mouse */
    Mouse(type:FlxMouseInputType);
    /** Any button or buttons on a virtual pad */
    VirtualPad(type:FlxMappedInputType<FlxVirtualPadInputID>);
}

enum FlxMappedInputType<T>
{
    Lone(id:T);
    Multi(ids:Array<T>);
}

class FlxControlMappedInputTools
{
    /**
     * Finds a device specific id for every input that can be attached to an action. For gamepads it will use
     * identifiers such as `WII_REMOTE(A)` or `PS4(SQUARE)`. For keyboard, the button label is returned.
     * for "Multi button" inputs (like analog WASD), an array is returned.
     */
    static public function toMappedInput(input:FlxControlInputType, activeGamepad:FlxGamepad):FlxControlMappedInput
    {
        function gPad(id:FlxGamepadInputID)
        {
            return activeGamepad != null
                ? activeGamepad.getMappedInput(id)
                : UNKNOWN(id);
        }
        
        inline function gPadMulti(up, down, right, left)
        {
            return Multi([gPad(up), gPad(down), gPad(right), gPad(left)]);
        }
        
        function key(id:FlxKey)
        {
            // TODO: find the label of this key (in international keyboards
            return id.toString();
        }
        
        inline function keyMulti(up, down, right, left)
        {
            return Multi([key(up), key(down), key(right), key(left)]);
        }
        
        return switch input
        {
            // Gamepad
            case GamepadControl(Lone(id))         : Gamepad(Lone(gPad(id)));
            case GamepadControl(DPad)             : Gamepad(gPadMulti(DPAD_UP, DPAD_DOWN, DPAD_RIGHT, DPAD_LEFT));
            case GamepadControl(Face)             : Gamepad(gPadMulti(Y, A, B, X));
            case GamepadControl(LeftStickDigital) : Gamepad(gPadMulti(LS_UP, LS_DOWN, LS_RIGHT, LS_LEFT));
            case GamepadControl(RightStickDigital): Gamepad(gPadMulti(RS_UP, RS_DOWN, RS_RIGHT, RS_LEFT));
            case GamepadControl(Multi(up, down, null, null)) : Gamepad(Multi([gPad(up), gPad(down)]));
            case GamepadControl(Multi(up, down, right, left)): Gamepad(gPadMulti(up, down, right, left));
            
            // Keyboard
            case KeyboardControl(Lone(id)): Keyboard(Lone(key(id)));
            case KeyboardControl(WASD)    : Keyboard(keyMulti(W, S, A, LEFT));
            case KeyboardControl(Arrows)  : Keyboard(keyMulti(UP, DOWN, RIGHT, LEFT));
            case KeyboardControl(Multi(up, down, null, null)) : Keyboard(Multi([key(up), key(down)]));
            case KeyboardControl(Multi(up, down, right, left)): Keyboard(keyMulti(up, down, right, left));
            
            // Virtual Pad
            case VirtualPadControl(Lone(id)): VirtualPad(Lone(id));
            case VirtualPadControl(Arrows)  : VirtualPad(Multi([UP, DOWN, RIGHT, LEFT]));
            case VirtualPadControl(Multi(up, down, null, null)) : VirtualPad(Multi([up, down]));
            case VirtualPadControl(Multi(up, down, right, left)): VirtualPad(Multi([up, down, right, left]));
            
            // Mouse
            case MouseControl(input): Mouse(input);
        }
    }
}