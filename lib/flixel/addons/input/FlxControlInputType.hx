package flixel.addons.input;

import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.gamepad.FlxGamepad;
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
    Keyboard(type:FlxKeyInputType);
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
        return Keyboard(Lone(id));
    }
    
    @:from
    static public function fromKeyList(ids:Array<FlxKey>):FlxControlInputType
    {
        if (ids.length == 2)
        {
            ids.push(null);
            ids.push(null);
        }
        else if (ids.length != 4)
            throw 'Invalid key list: $ids, expected length of 4 or 2';
        
        return Keyboard(Multi(ids[0], ids[1], ids[2], ids[3]));
    }
    
    @:from
    static public function fromKeyType(type:FlxKeyInputType):FlxControlInputType
    {
        return Keyboard(type);
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
    
    static final gamepadAnalogTriggers:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER];
    static final gamepadAnalogSticks:ReadOnlyArray<FlxGamepadInputID> = [LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    static final gamepadAnalogInputs:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    
    /** Whether the input can be added to a analog set */
    public function isAnalog()
    {
        return switch this
        {
            case Gamepad(id) if (gamepadAnalogInputs.contains(id)):
                true;
                
            case Keyboard(Multi(_, _, _, _)):
                true;
                
            case Mouse(Button(id)):
                false;
                
            case Mouse(_):
                true;
                
            case Keyboard(Lone(_)) | VirtualPad(_) | Gamepad(_):
                false;
        }
    }
    
    /** Whether the input can be added to a digital set */
    public function isDigital()
    {
        return switch this
        {
            // note: triggers can be digital (maybe sticks too?)
            case Gamepad(id) if (gamepadAnalogSticks.contains(id)):
                false;
                
            case Keyboard(Multi(_, _, _, _)):
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
                axis1 == axis2
                && id1 == id2;
                
            case [Mouse(Position(axis1)), Mouse(Position(axis2))]:
                axis1 == axis2;
                
            case [Keyboard(Lone(id1)), Keyboard(Lone(id2))]:
                id1 == id2;
                
            case [Keyboard(Multi(up1, down1, right1, left1)), Keyboard(Multi(up2, down2, right2, left2))]:
                up1 == up2
                && down1 == down2
                && right1 == right2
                && left1 == left2;
                
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
                
            default:
                compare(input);
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
    
    public function getLabel(activeGamepad:FlxGamepad):String
    {
        return switch this
        {
            case Gamepad(id) if (activeGamepad != null):
                activeGamepad.getInputLabel(id);
            case Gamepad(id):
                id.toString();
            case Keyboard(Lone(id)):
                id.toString();
            case Keyboard(Multi(up, down, null, null)):
                up.toString() + ", " + down.toString();
            case Keyboard(Multi(up, down, right, left)):
                up.toString() + ", " + down.toString() + ", " + up.toString() + ", " + down.toString();
            case VirtualPad(id):
                cast id;
            case Mouse(Button(LEFT)):
                "click";
            case Mouse(Button(RIGHT)):
                "right-click";
            case Mouse(Button(MIDDLE)):
                "middle-click";
            case Mouse(Position(_)) | Mouse(Motion(_)):
                "mouse";
            case Mouse(Drag(_)):
                "mouse-drag";
            default:
                "";
        }
    }
}

enum FlxKeyInputType
{
    Lone(id:FlxKey);
    Multi(up:FlxKey, down:FlxKey, ?right:FlxKey, ?left:FlxKey);
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