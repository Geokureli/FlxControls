package flixel.addons.input.actions;

import flixel.FlxG;
import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxAxes;

class AnalogAction extends FlxActionInputAnalog
{
    final _deviceID:FlxDeviceID;
    
    public function new (device, inputId, trigger:FlxAnalogState, axes = EITHER, deviceID = FlxDeviceID.FIRST_ACTIVE)
    {
        _deviceID = deviceID;
        #if (flixel < "5.9.0")
        final trigger:FlxInputState = cast trigger;
        #end
        super(device, inputId, trigger, axes, deviceID.toLegacy());
    }
    
    inline function getDeviceID()
    {
        return _deviceID;
    }
}

class AnalogGamepadAction extends AnalogAction
{
    /**
    * Gamepad action input for analog (trigger, joystick, touchpad, etc) events
    * @param   inputID    "universal" gamepad input ID (LEFT_TRIGGER, RIGHT_ANALOG_STICK, TILT_PITCH, etc)
    * @param   trigger    What state triggers this action (MOVED, JUST_MOVED, STOPPED, JUST_STOPPED)
    * @param   axis       which axes to monitor for triggering: X, Y, EITHER, or BOTH
    * @param   gamepadID  specific gamepad ID, or FlxInputDeviceID.FIRST_ACTIVE / ALL
    */
    public function new(inputID:FlxGamepadInputID, trigger, axis = FlxAnalogAxis.EITHER, gamepadID = FlxDeviceID.FIRST_ACTIVE)
    {
        super(FlxInputDevice.GAMEPAD, inputID, trigger, axis, gamepadID);
        checkInputId(inputID);
    }
    
    function checkInputId(inputID:FlxGamepadInputID)
    {
        switch (inputID)
        {
            case LEFT_ANALOG_STICK | RIGHT_ANALOG_STICK
                | LEFT_TRIGGER | RIGHT_TRIGGER
                | POINTER_X | POINTER_Y
                | DPAD:
            case found:
                throw 'Unexpected inputID: $found';
        }
    }
    
    override public function update():Void
    {
        #if FLX_GAMEPAD
        final numPads = FlxG.gamepads.numActiveGamepads;
        switch getDeviceID()
        {
            case ALL:
                for (i in 0...numPads)
                {
                    if (pollGamepad(FlxG.gamepads.getByID(i)))
                        break;
                }
            case FIRST_ACTIVE:
                pollGamepadSafe(FlxG.gamepads.getFirstActiveGamepad());
            case ID(id) if (numPads > id):
                pollGamepadSafe(FlxG.gamepads.getByID(id));
            case NONE | ID(_):
                updateValues(0, 0);
        }
        #else
        updateValues(0, 0);
        #end
    }
    
    #if FLX_GAMEPAD
    function pollGamepadSafe(gamepad:Null<FlxGamepad>):Bool
    {
        if (gamepad != null)
            return pollGamepad(gamepad);
        
        updateValues(0, 0);
        return false;
    }
    
    function pollGamepad(gamepad:FlxGamepad):Bool
    {
        inline function updateHelper(x:Float, y:Float):Bool
        {
            updateValues(x, y);
            return x != 0 || y != 0;
        }
        
        final values = gamepad.analog.value;
        return switch (inputID:FlxGamepadInputID)
        {
            case FlxGamepadInputID.LEFT_ANALOG_STICK:
                updateHelper(values.LEFT_STICK_X, values.LEFT_STICK_Y);
                
            case FlxGamepadInputID.RIGHT_ANALOG_STICK:
                updateHelper(values.RIGHT_STICK_X, values.RIGHT_STICK_Y);
                
            case FlxGamepadInputID.LEFT_TRIGGER:
                updateHelper(values.LEFT_TRIGGER, 0);
            
            case FlxGamepadInputID.RIGHT_TRIGGER:
                updateHelper(values.RIGHT_TRIGGER, 0);
                
            case FlxGamepadInputID.POINTER_X:
                updateHelper(values.POINTER_X, 0);
                
            case FlxGamepadInputID.POINTER_Y:
                updateHelper(values.POINTER_Y, 0);
                
            case FlxGamepadInputID.DPAD:
                final pressed = gamepad.pressed;
                updateHelper
                    ( (pressed.DPAD_RIGHT ? 1 : 0) - (pressed.DPAD_LEFT ? 1 : 0)
                    , (pressed.DPAD_DOWN  ? 1 : 0) - (pressed.DPAD_UP   ? 1 : 0)
                    );
            case found:
                throw 'Unexpected inputID: $found';
        }
    }
    #end
    
    override function updateValues(x:Float, y:Float)
    {
        super.updateValues(x, -y);
    }
}

function checkKey(key:FlxKey):Float
{
    #if FLX_KEYBOARD
    return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
    #else
    return 0.0;
    #end
}

class Analog1DKeysAction extends AnalogAction
{
    public var up:FlxKey;
    public var down:FlxKey;
    
    public function new (trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(KEYBOARD, -1, trigger, X);
    }
    
    override function update()
    {
        #if FLX_KEYBOARD
        final newX = checkKey(up) - checkKey(down);
        updateValues(newX, 0);
        #end
    }
}

class Analog2DKeysAction extends AnalogAction
{
    public var up:FlxKey;
    public var down:FlxKey;
    public var right:FlxKey;
    public var left:FlxKey;
    
    public function new (trigger:FlxAnalogState, up, down, right, left)
    {
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(KEYBOARD, -1, trigger, EITHER);
    }
    
    override function update()
    {
        #if FLX_KEYBOARD
        final newX = checkKey(right) - checkKey(left);
        final newY = checkKey(up) - checkKey(down);
        
        final scale = newX * newY == 0 ? 1 : (1 / FlxMath.SQUARE_ROOT_OF_TWO);
        updateValues(newX * scale, newY * scale);
        #end
    }
}

inline function checkPad(id:FlxGamepadInputID, gamepadID:FlxDeviceID):Float
{
    return checkPadBool(id, gamepadID) ? 1.0 : 0.0;
}

function checkPadBool(id:FlxGamepadInputID, gamepadID:FlxDeviceID):Bool
{
    #if FLX_GAMEPAD
    return switch gamepadID
    {
        case FlxDeviceID.ID(id):
            final gamepad = FlxG.gamepads.getByID(id);
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxDeviceID.FIRST_ACTIVE:
            final gamepad = FlxG.gamepads.getFirstActiveGamepad();
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxDeviceID.ALL:
            FlxG.gamepads.anyPressed(id);
        case FlxDeviceID.NONE:
            false;
    }
    #else
    return false;
    #end
}

class Analog1DGamepadAction extends AnalogAction
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    
    public function new (gamepadID:FlxDeviceID, trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(GAMEPAD, -1, trigger, X, gamepadID);
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(up, getDeviceID()) - checkPad(down, getDeviceID());
        updateValues(newX, 0);
        #end
    }
}

class Analog2DGamepadAction extends AnalogAction
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    public var right:FlxGamepadInputID;
    public var left:FlxGamepadInputID;
    
    public function new (gamepadID:FlxDeviceID, trigger:FlxAnalogState, up, down, right, left)
    {
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(GAMEPAD, -1, trigger, EITHER, gamepadID);
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(right, getDeviceID()) - checkPad(left, getDeviceID());
        final newY = checkPad(up, getDeviceID()) - checkPad(down, getDeviceID());
        updateValues(newX, newY);
        #end
    }
}

inline function checkVPad(id:FlxVirtualPadInputID, proxies:VPadMap):Float
{
    return proxies[id].pressed ? 1.0 : 0.0;
}


class Analog1DVPadAction extends AnalogAction
{
    public var proxies:VPadMap;
    public var up:FlxVirtualPadInputID;
    public var down:FlxVirtualPadInputID;
    
    public function new (proxies:VPadMap, trigger:FlxAnalogState, up, down)
    {
        this.proxies = proxies;
        this.up = up;
        this.down = down;
        super(IFLXINPUT_OBJECT, -1, trigger, X);
    }
    
    override function update()
    {
        #if FLX_MOUSE
        final newX = checkVPad(up, proxies) - checkVPad(down, proxies);
        updateValues(newX, 0);
        #end
    }
    
    override function destroy()
    {
        super.destroy();
        proxies = null;
    }
}

class Analog2DVPadAction extends AnalogAction
{
    public var proxies:VPadMap;
    public var up:FlxVirtualPadInputID;
    public var down:FlxVirtualPadInputID;
    public var right:FlxVirtualPadInputID;
    public var left:FlxVirtualPadInputID;
    
    public function new (proxies:VPadMap, trigger:FlxAnalogState, up, down, right, left)
    {
        this.proxies = proxies;
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(IFLXINPUT_OBJECT, -1, trigger, EITHER);
    }
    
    override function update()
    {
        #if FLX_MOUSE
        final newX = checkVPad(right, proxies) - checkVPad(left, proxies);
        final newY = checkVPad(up, proxies) - checkVPad(down, proxies);
        updateValues(newX, newY);
        #end
    }
    
    override function destroy()
    {
        super.destroy();
        proxies = null;
    }
}

class AnalogMouseDragAction extends FlxActionInputAnalogClickAndDragMouseMotion
{
    public function new (buttonID, trigger, axis = EITHER, scale = 0.1, deadzone = 0.1, invert = FlxAxes.NONE)
    {
        // If only tracking y, set x to y, because 1d controls always check x
        super(buttonID, trigger, axis, Math.ceil(1.0 / scale), deadzone, invert.y, invert.x);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}

class AnalogMouseMoveAction extends FlxActionInputAnalogMouseMotion
{
    public function new (trigger, axis = EITHER, scale = 0.1, deadzone = 0.1, invert = FlxAxes.NONE)
    {
        super(trigger, axis, Math.ceil(1.0 / scale), deadzone, invert.y, invert.x);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        // If only tracking y, set x to y, because 1d controls always check x
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}

class AnalogMousePositionAction extends FlxActionInputAnalogMousePosition
{
    public function new (trigger, axis = EITHER)
    {
        super(trigger, axis);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        // If only tracking y, set x to y, because 1d controls always check x
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}

class AnalogMouseWheelAction extends AnalogAction
{
    final scale:Float;
    
    public function new (trigger, scale = 0.1)
    {
        this.scale = scale;
        super(MOUSE, -1, trigger, X);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        #if FLX_MOUSE
        super.updateValues(FlxG.mouse.wheel * scale, 0);
        #else
        super.updateValues(0, 0);
        #end
    }
}