package flixel.addons.input;

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