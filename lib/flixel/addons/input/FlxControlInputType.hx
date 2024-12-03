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
    Gamepad(type:FlxGamepadInputType); // TODO: add deadzone
    /** Any button, or position/movement from the mouse */
    Mouse(type:FlxMouseInputType);
    /** Any button on a virtual pad */
    VirtualPad(type:FlxVirtualPadInputType);
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
        final ids = validateMulti(ids);
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
        return Gamepad(Lone(id));
    }
    
    @:from
    static public function fromGamepadList(ids:Array<FlxGamepadInputID>):FlxControlInputType
    {
        final ids = validateMulti(ids);
        return Gamepad(Multi(ids[0], ids[1], ids[2], ids[3]));
    }
    
    @:from
    static public function fromGamepadType(type:FlxGamepadInputType):FlxControlInputType
    {
        return Gamepad(type);
    }
    
    @:from
    static public function fromVirtualPad(id:FlxVirtualPadInputID):FlxControlInputType
    {
        return VirtualPad(Lone(id));
    }
    
    @:from
    static public function fromVirtualPadList(ids:Array<FlxVirtualPadInputID>):FlxControlInputType
    {
        final ids = validateMulti(ids);
        return VirtualPad(Multi(ids[0], ids[1], ids[2], ids[3]));
    }
    
    @:from
    static public function fromVirtualPadType(type:FlxVirtualPadInputType):FlxControlInputType
    {
        return VirtualPad(type);
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
    
    static function validateMulti<T>(ids:Array<T>)
    {
        if (ids.length == 2)
        {
            ids.push(null);
            ids.push(null);
        }
        else if (ids.length != 4)
            throw 'Invalid key list: $ids, expected length of 4 or 2';
        
        return ids;
    }
    
    static final gamepadAnalogTriggers:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER];
    static final gamepadAnalogSticks:ReadOnlyArray<FlxGamepadInputID> = [LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    static final gamepadAnalogInputs:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    
    /** Whether the input can be added to a analog set */
    public function isAnalog()
    {
        return switch this
        {
            case Gamepad(Lone(id)) if (gamepadAnalogInputs.contains(id)):
                true;
            case Gamepad(Lone(_)):
                false;
            case Gamepad(Multi(_, _, _, _))
                | Gamepad(DPad)
                | Gamepad(Face)
                | Gamepad(LeftStickDigital)
                | Gamepad(RightStickDigital):
                true;
                
            case Keyboard(Lone(_)):
                false;
            case Keyboard(Multi(_, _, _, _))
                | Keyboard(Arrows)
                | Keyboard(WASD):
                true;
                
            case VirtualPad(Lone(_)):
                false;
            case VirtualPad(Multi(_, _, _, _))
                | VirtualPad(Arrows):
                true;
                
            case Mouse(Button(id)):
                false;
            case Mouse(Motion(_, _, _, _))
                | Mouse(Position(_))
                | Mouse(Drag(_, _, _, _, _))
                | Mouse(Wheel(_)):
                true;
        }
    }
    
    /** Whether the input can be added to a digital set */
    public function isDigital()
    {
        return switch this
        {
            // note: triggers can be digital (maybe sticks too?)
            case Gamepad(Lone(id)) if (gamepadAnalogSticks.contains(id)):
                false;
            case Gamepad(Lone(id)):
                true;
            case Gamepad(Multi(_, _, _, _))
                | Gamepad(DPad)
                | Gamepad(Face)
                | Gamepad(LeftStickDigital)
                | Gamepad(RightStickDigital):
                false;
                
            case Keyboard(Lone(_)):
                true;
            case Keyboard(Multi(_, _, _, _))
                | Keyboard(Arrows)
                | Keyboard(WASD):
                false;
                
            case VirtualPad(Lone(_)):
                true;
            case VirtualPad(Multi(_, _, _, _))
                | VirtualPad(Arrows):
                false;
                
            case Mouse(Button(id)):
                true;
            case Mouse(Motion(_, _, _, _))
                | Mouse(Position(_))
                | Mouse(Drag(_, _, _, _, _))
                | Mouse(Wheel(_)):
                false;
        }
    }
    
    public function simplify()
    {
        return switch this
        {
            case Keyboard(WASD):
                Keyboard(Multi(W, S, D, A));
            case Keyboard(Arrows):
                Keyboard(Multi(UP, DOWN, RIGHT, LEFT));
            case Gamepad(DPad):
                Gamepad(Multi(DPAD_UP, DPAD_DOWN, DPAD_RIGHT, DPAD_LEFT));
            case Gamepad(Face):
                Gamepad(Multi(Y, A, B, X));
            case Gamepad(LeftStickDigital):
                Gamepad(Multi(LEFT_STICK_DIGITAL_UP, LEFT_STICK_DIGITAL_DOWN, LEFT_STICK_DIGITAL_RIGHT, LEFT_STICK_DIGITAL_LEFT));
            case Gamepad(RightStickDigital):
                Gamepad(Multi(RIGHT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_LEFT));
            case VirtualPad(Arrows):
                VirtualPad(Multi(UP, DOWN, RIGHT, LEFT));
            case Keyboard(Lone(_))
                | Gamepad(Lone(_))
                | VirtualPad(Lone(_))
                | Keyboard(Multi(_, _, _, _))
                | Gamepad(Multi(_, _, _, _))
                | VirtualPad(Multi(_, _, _, _))
                | Mouse(_):
                this;
        }
    }
    
    public function conflicts(input:FlxControlInputType)
    {
        return switch [simplify(), input.simplify()]
        {
            case [Gamepad(Multi(up1, down1, left1, right1)), Gamepad(Multi(up2, down2, left2, right2))]:
                anyMatch([up1, up2, down1, down2, right1, right2, left1, left2]);
            case [Gamepad(Lone(id)), Gamepad(Multi(up, down, right, left))]:
                anyMatch([id, up, down, right, left]);
            case [Gamepad(Multi(up, down, right, left)), Gamepad(Lone(id))]:
                anyMatch([id, up, down, right, left]);
                
            case [Keyboard(Multi(up1, down1, right1, left1)), Keyboard(Multi(up2, down2, right2, left2))]:
                anyMatch([up1, up2, down1, down2, right1, right2, left1, left2]);
            case [Keyboard(Lone(id)), Keyboard(Multi(up, down, right, left))]:
                anyMatch([id, up, down, right, left]);
            case [Keyboard(Multi(up, down, right, left)), Keyboard(Lone(id))]:
                anyMatch([id, up, down, right, left]);
                
            case [VirtualPad(Multi(up1, down1, right1, left1)), VirtualPad(Multi(up2, down2, right2, left2))]:
                anyMatch([up1, up2, down1, down2, right1, right2, left1, left2]);
            case [VirtualPad(Lone(id)), VirtualPad(Multi(up, down, right, left))]:
                anyMatch([id, up, down, right, left]);
            case [VirtualPad(Multi(up, down, right, left)), VirtualPad(Lone(id))]:
                anyMatch([id, up, down, right, left]);
                
            default:
                compare(input);
        }
    }
    
    function anyMatch<T>(list:Array<T>)
    {
        var i = list.length;
        while (i-- > 0)
        {
            var j = i;
            while (j-- > 0)
            {
                if (list[i] == list[j] && list[i] != null)
                    return true;
            }
        }
        return false;
    }
    
    public function compare(input:FlxControlInputType)
    {
        return switch [this, input]
        {
            case [Gamepad(Lone(id1)), Gamepad(Lone(id2))]:
                id1 == id2;
                
            case [Gamepad(Multi(up1, down1, left1, right1)), Gamepad(Multi(up2, down2, left2, right2))]:
                up1 == up2
                && down1 == down2
                && right1 == right2
                && left1 == left2;
                
            case [Gamepad(DPad), Gamepad(DPad)]
                | [Gamepad(Face), Gamepad(Face)]
                | [Gamepad(LeftStickDigital), Gamepad(LeftStickDigital)]
                | [Gamepad(RightStickDigital), Gamepad(RightStickDigital)]:
                true;
                
            case [Mouse(Button(id1)), Mouse(Button(id2))]:
                id1 == id2;
                
            case [Mouse(Motion(axis1, _, _, _)), Mouse(Motion(axis2, _, _, _))]:
                axis1 == axis2;
                
            case [Mouse(Drag(id1, axis1, _, _, _)), Mouse(Drag(id2, axis2, _, _, _))]:
                axis1 == axis2
                && id1 == id2;
                
            case [Mouse(Position(axis1)), Mouse(Position(axis2))]:
                axis1 == axis2;
                
                
            case [Mouse(Wheel(_)), Mouse(Wheel(_))]:
                true;
                
            case [Keyboard(Lone(id1)), Keyboard(Lone(id2))]:
                id1 == id2;
                
            case [Keyboard(Multi(up1, down1, right1, left1)), Keyboard(Multi(up2, down2, right2, left2))]:
                up1 == up2
                && down1 == down2
                && right1 == right2
                && left1 == left2;
                
            case [Keyboard(WASD), Keyboard(WASD)]
                | [Keyboard(Arrows), Keyboard(Arrows)]:
                true;
                
            case [VirtualPad(Lone(id1)), VirtualPad(Lone(id2))]:
                id1 == id2;
                
            case [VirtualPad(Multi(up1, down1, right1, left1)), VirtualPad(Multi(up2, down2, right2, left2))]:
                up1 == up2
                && down1 == down2
                && right1 == right2
                && left1 == left2;
                
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
        function gPad(id:FlxGamepadInputID)
        {
            return activeGamepad != null
                ? activeGamepad.getInputLabel(id)
                : id.toString();
        }
        
        function key(id:FlxKey)
        {
            return id.toString();
        }
        
        function vpad(id:FlxVirtualPadInputID)
        {
            return cast id;
        }
        
        return switch this
        {
            // Gamepad
            case Gamepad(Lone(id)):
                gPad(id);
            case Gamepad(Multi(up, down, null, null)):
                gPad(up) + "," + gPad(down);
            case Gamepad(Multi(up, down, right, left)):
                gPad(up) + "," + gPad(down) + "," + gPad(right) + "," + gPad(left);
            case Gamepad(DPad):
                "d-pad";
            case Gamepad(Face):
                "abxy";
            case Gamepad(LeftStickDigital):
                gPad(LEFT_ANALOG_STICK);
            case Gamepad(RightStickDigital):
                gPad(RIGHT_ANALOG_STICK);
            
            // Keyboard
            case Keyboard(Lone(id)):
                key(id);
            case Keyboard(Multi(up, down, null, null)):
                key(up) + "," + key(down);
            case Keyboard(Multi(up, down, right, left)):
                key(up) + "," + key(down) + "," + key(right) + "," + key(left);
            case Keyboard(WASD):
                "wasd";
            case Keyboard(Arrows):
                "arrows";
            
            // Virtual Pad
            case VirtualPad(Lone(id)):
                vpad(id);
            case VirtualPad(Multi(up, down, null, null)):
                vpad(up) + "," + vpad(down);
            case VirtualPad(Multi(up, down, right, left)):
                vpad(up) + "," + vpad(down) + "," + vpad(right) + "," + vpad(left);
            case VirtualPad(Arrows):
                "arrows";
            
            // Mouse
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
            case Mouse(Wheel(_)):
                "mouse-wheel";
            default:
                "";
        }
    }
    
    #if (flixel >= "5.9.0")
    /**
     * Finds a device specific id for every input that can be attached to an action. For gamepads it will use
     * identifiers such as `WII_REMOTE(A)` or `PS4(SQUARE)`. For keyboard, the button label is returned.
     * for "Multi button" inputs (like analog WASD), an array is returned.
     */
    inline public function getMappedInput(activeGamepad:FlxGamepad)
    {
        return flixel.addons.input.FlxControlMappedInput.FlxControlMappedInputTools.toMappedInput(this, activeGamepad);
    }
    #end
}

enum FlxKeyInputType
{
    /**
     * A single input, the default. You should rarely need to specify this, as it's assumed
     */
    Lone(id:FlxKey);
    
    /**
     * Used to define analog-like behavior using multiple digital inputs
     */
    Multi(up:FlxKey, down:FlxKey, ?right:FlxKey, ?left:FlxKey);
    
    /**
     * Easy way to add arrows keys as a single analog input
     */
    Arrows;
    
    /**
     * Easy way to add WASD keys as a single analog input
     */
    WASD;
}

enum FlxGamepadInputType
{
    /**
     * A single input, the default. You should rarely need to specify this, as it's assumed
     */
    Lone(id:FlxGamepadInputID);
    
    /**
     * Used to define analog-like behavior using multiple digital inputs
     */
    Multi(up:FlxGamepadInputID, down:FlxGamepadInputID, ?right:FlxGamepadInputID, ?left:FlxGamepadInputID);
    
    /**
     * Easy way to add D-pad buttons as a single analog input
     */
    DPad;
    
    /**
     * Easy way to add face buttons (i.e.: ABXY) as a single analog input
     */
    Face;
    
    /**
     * Helper for an analog input made of the four digital inputs from the left stick.
     * **Note:** Actions using this will only have x and y values of `-1`, `0` and `1`, whereas
     * `LEFT_ANALOG_STICK`, will read the raw `x` and/or `y` of the stick
     */
    LeftStickDigital;
    
    /**
     * Helper for an analog input made of the four digital inputs from the right stick.
     * **Note:** Actions using this will only have x and y values of `-1`, `0` and `1`, whereas
     * `RIGHT_ANALOG_STICK`, will read the raw `x` and/or `y` of the stick
     */
    RightStickDigital;
}

enum FlxVirtualPadInputType
{
    /**
     * A single input, the default. You should rarely need to specify this, as it's assumed
     */
    Lone(id:FlxVirtualPadInputID);
    
    /**
     * Used to define analog-like behavior using multiple digital inputs
     */
    Multi(up:FlxVirtualPadInputID, down:FlxVirtualPadInputID, ?right:FlxVirtualPadInputID, ?left:FlxVirtualPadInputID);
    
    /**
     * Easy way to add arrows buttons as a single analog input
     */
    Arrows;
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
    
    /**
     * @param   scale  Multiplies the value
     */
    Wheel(?scale:Float);// TODO: Unify values on Html5/C
    
    // TODO: scroll?
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