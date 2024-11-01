package flixel.addons.input;

import flixel.addons.input.FlxControlInputType;
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
            case FlxControlInputTypeRaw.Gamepad(Lone(id)):
                FlxControlMappedInput.Gamepad(FlxMappedInputType.Lone(gPad(id)));
            case FlxControlInputTypeRaw.Gamepad(Multi(up, down, null, null)):
                FlxControlMappedInput.Gamepad(FlxMappedInputType.Multi([gPad(up), gPad(down)]));
            case FlxControlInputTypeRaw.Gamepad(Multi(up, down, right, left)):
                FlxControlMappedInput.Gamepad(FlxMappedInputType.Multi([gPad(up), gPad(down), gPad(right), gPad(left)]));
            case FlxControlInputTypeRaw.Gamepad(DPad):
                FlxControlMappedInput.Gamepad(FlxMappedInputType.Multi([gPad(DPAD_UP), gPad(DPAD_DOWN), gPad(DPAD_RIGHT), gPad(DPAD_LEFT)]));
            case FlxControlInputTypeRaw.Gamepad(Face):
                FlxControlMappedInput.Gamepad(FlxMappedInputType.Multi([gPad(Y), gPad(A), gPad(B), gPad(X)]));
            
            // Keyboard
            case FlxControlInputTypeRaw.Keyboard(Lone(id)):
                FlxControlMappedInput.Keyboard(FlxMappedInputType.Lone(key(id)));
            case FlxControlInputTypeRaw.Keyboard(Multi(up, down, null, null)):
                FlxControlMappedInput.Keyboard(FlxMappedInputType.Multi([key(up), key(down)]));
            case FlxControlInputTypeRaw.Keyboard(Multi(up, down, right, left)):
                FlxControlMappedInput.Keyboard(FlxMappedInputType.Multi([key(up), key(down), key(right), key(left)]));
            case FlxControlInputTypeRaw.Keyboard(WASD):
                FlxControlMappedInput.Keyboard(FlxMappedInputType.Multi([key(W), key(S), key(A), key(LEFT)]));
            case FlxControlInputTypeRaw.Keyboard(Arrows):
                FlxControlMappedInput.Keyboard(FlxMappedInputType.Multi([key(UP), key(DOWN), key(RIGHT), key(LEFT)]));
            
            // Virtual Pad
            case FlxControlInputTypeRaw.VirtualPad(Lone(id)):
                FlxControlMappedInput.VirtualPad(FlxMappedInputType.Lone(id));
            case FlxControlInputTypeRaw.VirtualPad(Multi(up, down, null, null)):
                FlxControlMappedInput.VirtualPad(FlxMappedInputType.Multi([up, down]));
            case FlxControlInputTypeRaw.VirtualPad(Multi(up, down, right, left)):
                FlxControlMappedInput.VirtualPad(FlxMappedInputType.Multi([up, down, right, left]));
            case FlxControlInputTypeRaw.VirtualPad(Arrows):
                FlxControlMappedInput.VirtualPad(FlxMappedInputType.Multi([UP, DOWN, RIGHT, LEFT]));
            
            // Mouse
            case FlxControlInputTypeRaw.Mouse(Button(LEFT)):
                FlxControlMappedInput.Mouse(Button(LEFT));
            case FlxControlInputTypeRaw.Mouse(Button(RIGHT)):
                FlxControlMappedInput.Mouse(Button(RIGHT));
            case FlxControlInputTypeRaw.Mouse(Button(MIDDLE)):
                FlxControlMappedInput.Mouse(Button(MIDDLE));
            case FlxControlInputTypeRaw.Mouse(Position(axis)):
                FlxControlMappedInput.Mouse(Position(axis));
            case FlxControlInputTypeRaw.Mouse(Motion(axis, scale, deadzone, invert)):
                FlxControlMappedInput.Mouse(Motion(axis, scale, deadzone, invert));
            case FlxControlInputTypeRaw.Mouse(Drag(id, axis, scale, deadzone, invert)):
                FlxControlMappedInput.Mouse(Drag(id, axis, scale, deadzone, invert));
            default:
                throw 'Internal Error - unexpected input:"$input"';
        }
    }
}