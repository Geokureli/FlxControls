package flixel.addons.input;

import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseButton;
import flixel.util.FlxAxes;
import haxe.ds.ReadOnlyArray;

/**
 * Defines a hidden enum: `FlxControlInputTypeRaw`, which is abstracted by `FlxControlInputType`,
 * allowing it to have implicit converters and methods
 */
enum FlxControlInputTypeRaw
{
    /** A button on a keyboard */
    Keyboard(id:FlxKey);
    /** Any button, analog stick or trigger on a gamepad */
    Gamepad(id:FlxGamepadInputID); // TODO: add deadzone
    /** Any button, or position/movement from the mouse */
    Mouse(type:FlxMouseInputType);
    /** Any button on a virtual pad */
    VirtualPad(id:FlxVirtualPadInputID);
}

/**
 * Defines all possible input devices
 */
abstract FlxControlInputType(FlxControlInputTypeRaw) from FlxControlInputTypeRaw
{
    @:from
    static public function fromKey(id:FlxKey):FlxControlInputType
    {
        return Keyboard(id);
    }
    
    @:from
    static public function fromGamepad(id:FlxGamepadInputID):FlxControlInputType
    {
        return Gamepad(id);
    }
    
    @:from
    static public function fromVirtualPad(id:FlxVirtualPadInputID):FlxControlInputType
    {
        return VirtualPad(id);
    }
    
    @:from
    static public function fromMouseButton(id:FlxMouseButtonID):FlxControlInputType
    {
        return Mouse(Button(id));
    }
    
    @:from
    static public function fromMouse(type:FlxMouseInputType):FlxControlInputType
    {
        return Mouse(type);
    }
    
    static final gamepadAnalogInputs:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    public function isDigital()
    {
        return switch this
        {
            case Gamepad(id) if (gamepadAnalogInputs.contains(id)):
                false;
                
            case Mouse(Button(id)):
                true;
                
            case Mouse(_):
                false;
                
            case Keyboard(_) | VirtualPad(_) | Gamepad(_):
                true;
        }
    }
    
    public function compare(input:FlxControlInputType)
    {
        return switch [this, input]
        {
            case [Gamepad(id1), Gamepad(id2)]:
                id1 == id2;
                
            case [Mouse(Button(id1)), Mouse(Button(id2))]:
                id1 == id2;
                
            case [Mouse(Motion(axis1, _, _, _)), Mouse(Motion(axis2, _, _, _))]:
                axis1 == axis2;
                
            case [Mouse(Drag(id1, axis1, _, _, _)), Mouse(Drag(id2, axis2, _, _, _))]:
                axis1 == axis2 && id1 == id2;
                
            case [Mouse(Position(axis1)), Mouse(Position(axis2))]:
                axis1 == axis2;
                
            case [Keyboard(id1), Keyboard(id2)]:
                id1 == id2;
                
            case [VirtualPad(id1), VirtualPad(id2)]:
                id1 == id2;
                
            default:
                false;
        }
    }
    
    public function compareStrict(input:FlxControlInputType)
    {
        return switch [this, input]
        {
            case [Gamepad(id1), Gamepad(id2)]:
                id1 == id2;
                
            case [Mouse(Button(id1)), Mouse(Button(id2))]:
                id1 == id2;
                
            case [Mouse(Motion(axis1, scale1, deadzone1, invert1)), Mouse(Motion(axis2, scale2, deadzone2, invert2))]:
                axis1 == axis2
                && scale1 == scale2
                && deadzone1 == deadzone2
                && invert1 == invert2;
                
            case [Mouse(Drag(id1, axis1, scale1, deadzone1, invert1)), Mouse(Drag(id2, axis2, scale2, deadzone2, invert2))]:
                id1 == id2
                && axis1 == axis2
                && scale1 == scale2
                && deadzone1 == deadzone2
                && invert1 == invert2;
                
            case [Mouse(Position(axis1)), Mouse(Position(axis2))]:
                axis1 == axis2;
                
            case [Keyboard(id1), Keyboard(id2)]:
                id1 == id2;
                
            case [VirtualPad(id1), VirtualPad(id2)]:
                id1 == id2;
                
            default:
                false;
        }
    }
    
    public function getDevice():FlxInputDevice
    {
        return switch this
        {
            case Gamepad(_)   : FlxInputDevice.GAMEPAD;
            case Mouse(_)     : FlxInputDevice.MOUSE;
            case Keyboard(_)  : FlxInputDevice.KEYBOARD;
            case VirtualPad(_): FlxInputDevice.IFLXINPUT_OBJECT;
        }
    }
}

enum FlxMouseInputType
{
    /**
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     */
    Position(?axis:FlxAnalogAxis);
    
    /**
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     * @param   scale     Applied to the raw mouse motion. The default `0.1` means moving the
     *                    mouse 10px right will have a value of `1.0`
     * @param   deadzone  A value less than this will be considered `0`, defaults to `0.1`
     * @param   invert    Whether to invert one or both of the axes, defaults to `NONE`
     */
    Motion(?axis:FlxAnalogAxis, ?scale:Float, ?deadzone:Float, ?invert:FlxAxes);
    
    /**
     * @param   id        The id of the mouse button used to drag, defaults to left click
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     * @param   scale     Applied to the raw mouse motion. The default `0.1` means moving the
     *                    mouse 10px right will have a value of `1.0`
     * @param   deadzone  A value less than this will be considered `0`, defaults to `0.1`
     * @param   invert    Whether to invert one or both of the axes, defaults to `NONE`
     */
    Drag(?id:FlxMouseButtonID, ?axis:FlxAnalogAxis, ?scale:Float, ?deadzone:Float, ?invert:FlxAxes);
    
    /**
     * @param   id  The id of the mouse button used to drag, defaults to left click
     */
    Button(?id:FlxMouseButtonID);
    
    // TODO: Wheel, or scroll x/y
}

enum abstract FlxVirtualPadInputID(String)
{
    var UP    = "up";
    var DOWN  = "down";
    var LEFT  = "left";
    var RIGHT = "right";
    var A     = "a";
    var B     = "b";
    var C     = "c";
    var X     = "x";
    var Y     = "y";
}