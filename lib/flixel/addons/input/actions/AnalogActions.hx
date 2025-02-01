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
import flixel.input.mouse.FlxMouseButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;

class AnalogAction extends FlxActionInputAnalog
{
    final _deviceID:FlxDeviceID;
    final movedMode:AnalogActionMoveMove;
    
    public function new (device, inputId, trigger:FlxAnalogState, moveMode = ZERO, axes = EITHER, deviceID = FlxDeviceID.FIRST_ACTIVE)
    {
        _deviceID = deviceID;
        this.movedMode = moveMode;
        #if (flixel < version("5.9.0"))
        final trigger:FlxInputState = cast trigger;
        #end
        super(device, inputId, trigger, axes, deviceID.toLegacy());
    }
    
    inline function getDeviceID()
    {
        return _deviceID;
    }
    
    override function updateValues(x:Float, y:Float):Void
    {
        // If only tracking y, set x to y, because 1d controls always check x
        if (axis == Y)
            x = y;
        
        final movedX = switch movedMode
        {
            case ZERO: x != 0;
            case LAST: x != this.x;
        }
        final movedY = switch movedMode
        {
            case ZERO: y != 0;
            case LAST: y != this.y;
        }
        
        if (movedX)
            xMoved.press();
        else
            xMoved.release();

        if (movedY)
            yMoved.press();
        else
            yMoved.release();
        
        this.x = x;
        this.y = y;
    }
}

enum AnalogActionMoveMove
{
    /**
     * Any change from the previous value is considered moving
     */
    LAST;
    
    /**
     * Any non-zero value is considered moving
     */
    ZERO;
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
        super(FlxInputDevice.GAMEPAD, inputID, trigger, ZERO, axis, gamepadID);
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

class AnalogKeysAction extends AnalogAction
{
    public function new (trigger:FlxAnalogState, axis)
    {
        super(KEYBOARD, -1, trigger, ZERO, axis);
    }
    
    function checkKey(key:FlxKey):Float
    {
        #if FLX_KEYBOARD
        return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
        #else
        return 0.0;
        #end
    }
}

class Analog1DKeysAction extends AnalogKeysAction
{
    public var up:FlxKey;
    public var down:FlxKey;
    
    public function new (trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(trigger, X);
    }
    
    override function update()
    {
        #if FLX_KEYBOARD
        updateValues(checkKey(up) - checkKey(down), 0);
        #end
    }
}

class Analog2DKeysAction extends AnalogKeysAction
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
        
        super(trigger, EITHER);
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

class AnalogMultiGamepadAction extends AnalogAction
{
    public function new (gamepadID, trigger, axes)
    {
        super(GAMEPAD, -1, trigger, ZERO, axes, gamepadID);
    }
    
    inline function checkPad(id:FlxGamepadInputID):Float
    {
        return checkPadBool(id, getDeviceID()) ? 1.0 : 0.0;
    }

    static function checkPadBool(id:FlxGamepadInputID, gamepadID:FlxDeviceID):Bool
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
}
class Analog1DGamepadAction extends AnalogMultiGamepadAction
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    
    public function new (gamepadID, trigger, up, down)
    {
        this.up = up;
        this.down = down;
        super(gamepadID, trigger, X);
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(up) - checkPad(down);
        updateValues(newX, 0);
        #end
    }
}

class Analog2DGamepadAction extends AnalogMultiGamepadAction
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    public var right:FlxGamepadInputID;
    public var left:FlxGamepadInputID;
    
    public function new (gamepadID, trigger, up, down, right, left)
    {
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(gamepadID, trigger, EITHER);
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(right) - checkPad(left);
        final newY = checkPad(up) - checkPad(down);
        updateValues(newX, newY);
        #end
    }
}

#if (flixel >= version("6.0.0"))
class VPadStickAction extends AnalogAction
{
    final proxy:VirtualPadStickProxy;
    
    public function new (proxy, trigger)
    {
        this.proxy = proxy;
        super(OTHER, -1, trigger, ZERO, EITHER);
    }
    
    override function update()
    {
        if (proxy != null)
            updateValues(proxy.target.value.x, proxy.target.value.y);
    }
}
#end

class AnalogMultiVPadAction extends AnalogAction
{
    final proxies:VPadMap;
    
    public function new (proxies:VPadMap, trigger:FlxAnalogState, axis)
    {
        this.proxies = proxies;
        super(IFLXINPUT_OBJECT, -1, trigger, ZERO, axis);
    }
    
    inline function checkVPad(id:FlxVirtualPadInputID):Float
    {
        return proxies[id].pressed ? 1.0 : 0.0;
    }
}

class Analog1DVPadAction extends AnalogMultiVPadAction
{
    public final up:FlxVirtualPadInputID;
    public final down:FlxVirtualPadInputID;
    
    public function new (proxies, trigger, up, down)
    {
        this.up = up;
        this.down = down;
        super(proxies, trigger, X);
    }
    
    override function update()
    {
        #if FLX_MOUSE
        final newX = checkVPad(up) - checkVPad(down);
        updateValues(newX, 0);
        #end
    }
}

class Analog2DVPadAction extends AnalogMultiVPadAction
{
    public final up:FlxVirtualPadInputID;
    public final down:FlxVirtualPadInputID;
    public final right:FlxVirtualPadInputID;
    public final left:FlxVirtualPadInputID;
    
    public function new (proxies, trigger, up, down, right, left)
    {
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(proxies, trigger, EITHER);
    }
    
    override function update()
    {
        #if FLX_MOUSE
        final newX = checkVPad(right) - checkVPad(left);
        final newY = checkVPad(up) - checkVPad(down);
        updateValues(newX, newY);
        #else
        updateValues(0, 0);
        #end
    }
}

class AnalogMouseMoveAction extends AnalogAction
{
    final last = FlxPoint.get();
    
    public final scale:Float;
    public final deadzone:Float;
    public final invert:FlxAxes;
    public final max:Float = Math.POSITIVE_INFINITY; // TODO
    
    /**
     * Tracks the relative motion of thw mouse since the last frame
     * 
     * @param trigger   What state triggers this action (`MOVED`, `JUST_MOVED`, `STOPPED`, `JUST_STOPPED`)
     * @param axis      The axis to track movement
     * @param scale     Scales the x and y of the raw mouse movement
     * @param deadzone  Minimum analog value before movement is reported
     * @param invert    Which axes to invert
     */
    public function new (trigger, axis, scale, deadzone, invert)
    {
        this.scale = scale;
        this.deadzone = deadzone;
        this.invert = invert;
        
        super(FlxInputDevice.MOUSE, -1, trigger, ZERO, axis);
    }
    
    override function destroy()
    {
        super.destroy();
        last.put();
    }
    
    override public function update():Void
    {
        #if FLX_MOUSE
        updateXYPosition(FlxG.mouse.x, FlxG.mouse.y);
        #end
    }
    
    function updateXYPosition(x:Float, y:Float):Void
    {
        final xDiff = (x - last.x) * scale * (invert.x ? -1 : 1);
        final yDiff = (y - last.y) * scale * (invert.y ? -1 : 1);
        last.set(x, y);
        
        updateValues(checkDeadzone(xDiff, deadzone), checkDeadzone(yDiff, deadzone));
    }
    
    inline static function checkDeadzone(n:Float, deadzone:Float)
    {
        return n < deadzone && n > -deadzone ? 0 : n;
    }
}

class AnalogMouseDragAction extends AnalogMouseMoveAction
{
    final buttonID:FlxMouseButtonID;
    /**
     * Same as `AnalogMouseMoveAction` but requires a button to be held
     * 
     * @param buttonID  The button to hold when dragging
     * @param trigger   What state triggers this action (`MOVED`, `JUST_MOVED`, `STOPPED`, `JUST_STOPPED`)
     * @param axis      The axis to track movement
     * @param scale     Scales the x and y of the raw mouse movement
     * @param deadzone  Minimum analog value before movement is reported
     * @param invert    Which axes to invert
     */
    public function new (buttonID, trigger, axis, scale, deadzone, invert)
    {
        this.buttonID = buttonID;
        super(trigger, axis, scale, deadzone, invert);
    }
    
	override function updateValues(x:Float, y:Float):Void
	{
		#if FLX_MOUSE
		final pressed = switch buttonID
		{
			case LEFT: FlxG.mouse.pressed;
			case RIGHT: FlxG.mouse.pressedRight;
			case MIDDLE: FlxG.mouse.pressedMiddle;
		}
        if (pressed)
    		super.updateValues(x, y);
        else
            super.updateValues(0, 0);
		#end
	}
}

class AnalogMousePositionAction extends AnalogAction
{
    public function new (trigger, axis)
    {
        super(FlxInputDevice.MOUSE, -1, trigger, LAST, axis);
    }
    
    
    override function update():Void
    {
        #if !FLX_NO_MOUSE
        updateValues(FlxG.mouse.x, FlxG.mouse.y);
        #end
    }
}

class AnalogMouseWheelAction extends AnalogAction
{
    final scale:Float;
    
    public function new (trigger, scale = 0.1)
    {
        this.scale = scale;
        super(MOUSE, -1, trigger, ZERO, X);
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