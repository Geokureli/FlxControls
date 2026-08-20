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
        
        function key(id:FlxKey)
        {
            // TODO: find the label of this key (in international keyboards
            return id.toString();
        }
        
        return switch input
        {
            // Gamepad
            case GamepadControl(Lone(id)):
                Gamepad(Lone(gPad(id)));
            case GamepadControl(Multi(up, down, null, null)):
                Gamepad(Multi([gPad(up), gPad(down)]));
            case GamepadControl(Multi(up, down, right, left)):
                Gamepad(Multi([gPad(up), gPad(down), gPad(right), gPad(left)]));
            case GamepadControl(DPad):
                Gamepad(Multi([gPad(DPAD_UP), gPad(DPAD_DOWN), gPad(DPAD_RIGHT), gPad(DPAD_LEFT)]));
            case GamepadControl(Face):
                Gamepad(Multi([gPad(Y), gPad(A), gPad(B), gPad(X)]));
            case GamepadControl(LeftStickDigital):
                Gamepad(Multi([gPad(LEFT_STICK_DIGITAL_UP), gPad(LEFT_STICK_DIGITAL_DOWN), gPad(LEFT_STICK_DIGITAL_RIGHT), gPad(LEFT_STICK_DIGITAL_LEFT)]));
            case GamepadControl(RightStickDigital):
                Gamepad(Multi([gPad(RIGHT_STICK_DIGITAL_UP), gPad(RIGHT_STICK_DIGITAL_DOWN), gPad(RIGHT_STICK_DIGITAL_RIGHT), gPad(RIGHT_STICK_DIGITAL_LEFT)]));
            
            // Keyboard
            case KeyboardControl(Lone(id)):
                Keyboard(Lone(key(id)));
            case KeyboardControl(Multi(up, down, null, null)):
                Keyboard(Multi([key(up), key(down)]));
            case KeyboardControl(Multi(up, down, right, left)):
                Keyboard(Multi([key(up), key(down), key(right), key(left)]));
            case KeyboardControl(WASD):
                Keyboard(Multi([key(W), key(S), key(A), key(LEFT)]));
            case KeyboardControl(Arrows):
                Keyboard(Multi([key(UP), key(DOWN), key(RIGHT), key(LEFT)]));
            
            // Virtual Pad
            case VirtualPadControl(Lone(id)):
                VirtualPad(Lone(id));
            case VirtualPadControl(Multi(up, down, null, null)):
                VirtualPad(Multi([up, down]));
            case VirtualPadControl(Multi(up, down, right, left)):
                VirtualPad(Multi([up, down, right, left]));
            case VirtualPadControl(Arrows):
                VirtualPad(Multi([UP, DOWN, RIGHT, LEFT]));
            
            // Mouse
            case MouseControl(Button(LEFT)):
                Mouse(Button(LEFT));
            case MouseControl(Button(RIGHT)):
                Mouse(Button(RIGHT));
            case MouseControl(Button(MIDDLE)):
                Mouse(Button(MIDDLE));
            case MouseControl(Position(axis)):
                Mouse(Position(axis));
            case MouseControl(Motion(axis, scale, deadzone, invert)):
                Mouse(Motion(axis, scale, deadzone, invert));
            case MouseControl(Drag(id, axis, scale, deadzone, invert)):
                Mouse(Drag(id, axis, scale, deadzone, invert));
            case MouseControl(Wheel(scale)):
                Mouse(Wheel(scale));
            default:
                throw 'Internal error - Unexpexpected input: "$input"';
        }
    }
}