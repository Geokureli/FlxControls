package flixel.addons.input;

import flixel.FlxG;
import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxRepeatInput;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxAxes;
import flixel.util.FlxDirection;
import flixel.util.FlxDirectionFlags;

@:forward
abstract FlxAnalogSet1D<TAction:EnumValue>(FlxAnalogSet1DBase<TAction>) to FlxAnalogSet1DBase<TAction>
{
    /** The value of this action */
    public var value(get, never):Float;
    inline function get_value():Float { @:privateAccess return this.control.x; }
}

@:allow(flixel.addons.input.FlxAnalogDirections2D)
@:access(flixel.addons.input.FlxAnalogSet)
@:forward
abstract FlxAnalogSet1DBase<TAction:EnumValue>(FlxAnalogSet<TAction>) to FlxAnalogSet<TAction>
{
    /**
     * Helper for extracting digital directional states from an analog action.
     * For instance, if the action's `value` is positive, `pressed.up` will be `true`
     */
    public var pressed(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_pressed() return this.pressed;
    
    /**
     * Helper for extracting digital directional states from an analog action.
     * For instance, if the action's `value` just became positive, `justPressed.up` will be `true`
     */
    public var justPressed(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_justPressed() return this.justPressed;
    
    /**
     * Helper for extracting digital directional states from an analog action.
     * For instance, if the action's `value` is `0` or negative, `released.up` will be `true`
     */
    public var released(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_released() return this.released;
    
    /**
     * Helper for extracting digital directional states from an analog action.
     * For instance, if the action's `value` just became `0` or negative, `justReleased.up` will be `true`
     */
    public var justReleased(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_justReleased() return this.justReleased;
    
    /**
     * Helper for extracting digital directional states from an analog action.
     * It is similar to `justPressed` but holding the input for 0.5s will make it fire every 0.1s
     */
    public var holdRepeat(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_holdRepeat() return this.holdRepeat;
}

@:forward
abstract FlxAnalogSet2D<TAction:EnumValue>(FlxAnalogSet2DBase<TAction>) to FlxAnalogSet2DBase<TAction>
{
    /** The horizontal component of this 2D action */
    public var x(get, never):Float;
    /** The vertical component of this 2D action */
    public var y(get, never):Float;
    inline function get_x():Float { @:privateAccess return this.control.x; }
    inline function get_y():Float { @:privateAccess return this.control.y; }
}

@:allow(flixel.addons.input.FlxAnalogDirections2D)
@:forward
abstract FlxAnalogSet2DBase<TAction:EnumValue>(FlxAnalogSet<TAction>) to FlxAnalogSet<TAction>
{
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` is positive, `pressed.up` will be `true`
     */
    public var pressed(get, never):FlxAnalogDirections2D<TAction>;
    inline function get_pressed() return this.pressed;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` just became positive, `justPressed.up` will be `true`
     */
    public var justPressed(get, never):FlxAnalogDirections2D<TAction>;
    inline function get_justPressed() return this.justPressed;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` is `0` or negative, `released.up` will be `true`
     */
    public var released(get, never):FlxAnalogDirections2D<TAction>;
    inline function get_released() return this.released;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` just became `0` or negative, `justReleased.up` will be `true`
     */
    public var justReleased(get, never):FlxAnalogDirections2D<TAction>;
    inline function get_justReleased() return this.justReleased;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * It is similar to `justPressed` but holding the input for 0.5s will make it fire every 0.1s
     */
    public var holdRepeat(get, never):FlxAnalogDirections2D<TAction>;
    inline function get_holdRepeat() return this.holdRepeat;
}

/**
 * Manages analog actions. There is usually only 1 of these per FlxControls instance, and it's only
 * accessed by FlxControls, which offers ways to use the actions in this set.
 */
@:allow(flixel.addons.input.FlxControls)
@:allow(flixel.addons.input.FlxAnalogSet2DBase)
class FlxAnalogSet<TAction:EnumValue>
{
    final pressed:FlxAnalogDirections2D<TAction>;
    final justPressed:FlxAnalogDirections2D<TAction>;
    final released:FlxAnalogDirections2D<TAction>;
    final justReleased:FlxAnalogDirections2D<TAction>;
    final holdRepeat:FlxAnalogDirections2D<TAction>;
    
    var upInput = new FlxRepeatInput<FlxDirection>(UP);
    var downInput = new FlxRepeatInput<FlxDirection>(DOWN);
    var leftInput = new FlxRepeatInput<FlxDirection>(LEFT);
    var rightInput = new FlxRepeatInput<FlxDirection>(RIGHT);
    
    var control:FlxControlAnalog;
    var parent:FlxControls<TAction>;
    var name:String;
    
    function new(parent, action:TAction)
    {
        this.parent = parent;
        final namePrefix = '${parent.name}:${action.getName()}';
        name = '$namePrefix-analogSet';
        control = new FlxControlAnalog('$namePrefix-control', MOVED);
        
        pressed      = new FlxAnalogDirections2D(this, (i)->i.hasState(PRESSED      ));
        released     = new FlxAnalogDirections2D(this, (i)->i.hasState(RELEASED     ));
        justPressed  = new FlxAnalogDirections2D(this, (i)->i.hasState(JUST_PRESSED ));
        justReleased = new FlxAnalogDirections2D(this, (i)->i.hasState(JUST_RELEASED));
        holdRepeat   = new FlxAnalogDirections2D(this, (i)->i.triggerRepeat());
    }
    
    function destroy()
    {
        parent = null;
        
        pressed.destroy();
        justPressed.destroy();
        released.destroy();
        justReleased.destroy();
        holdRepeat.destroy();
    }
    
    function update()
    {
        control.update();
        
        upInput.updateWithState(control.y > 0);
        downInput.updateWithState(control.y < 0);
        rightInput.updateWithState(control.x > 0);
        leftInput.updateWithState(control.x < 0);
    }
    
    /**
     * Registers the control associated with the target action
     */
    function add(input:FlxControlInputType)
    {
        control.addInputType(parent, input);
    }
    
    /**
     * Unregisters the control associated with the target action
     */
    function remove(input:FlxControlInputType)
    {
        control.removeInputType(input);
    }
    
    function setGamepadID(id:FlxDeviceID)
    {
        control.setGamepadID(id);
    }
}

abstract FlxAnalogDirections1D<TAction:EnumValue>(FlxAnalogDirections2D<TAction>) from FlxAnalogDirections2D<TAction>
{
    /** The digital up component of this 2D action **/
    public var up(get, never):Bool;
    function get_up() return this.right;
    
    /** The digital down component of this 2D action **/
    public var down(get, never):Bool;
    function get_down() return this.left;
    
    public function toString()
    {
        return '( u: $up | d: $down )';
    }
}

@:allow(flixel.addons.input.FlxAnalogSet)
@:access(flixel.addons.input.FlxAnalogSet)
class FlxAnalogDirections2D<TAction:EnumValue>
{
    /** The digital up component of this 2D action **/
    public var up(get, never):Bool;
    inline function get_up() return func(set.upInput);
    
    /** The digital down component of this 2D action **/
    public var down(get, never):Bool;
    inline function get_down() return func(set.downInput);
    
    /** The digital left component of this 2D action **/
    public var left(get, never):Bool;
    inline function get_left() return func(set.leftInput);
    
    /** The digital right component of this 2D action **/
    public var right(get, never):Bool;
    inline function get_right() return func(set.rightInput);
    
    var set:FlxAnalogSet<TAction>;
    var func:(FlxRepeatInput<FlxDirection>)->Bool;
    
    function new(set, func)
    {
        this.set = set;
        this.func = func;
    }
    
    function destroy()
    {
        this.set = null;
        this.func = null;
    }
    
    public function toString()
    {
        return '( u: $up | d: $down | l: $left | r: $right)';
    }
    
    /**
     * Checks the digital component of the given direction. For example: `UP` will check `up`
     */
    public function check(dir:FlxDirection)
    {
        return switch dir
        {
            case UP: up;
            case DOWN: down;
            case LEFT: left;
            case RIGHT: right;
        }
    }
    
    /**
     * Checks the digital components of the given direction flags.
     * For example: `(UP | DOWN)` will check `up || down`
     */
    public function any(dir:FlxDirectionFlags)
    {
        return (dir.has(UP   ) && up   )
            || (dir.has(DOWN ) && down )
            || (dir.has(LEFT ) && left )
            || (dir.has(RIGHT) && right);
    }
}

/**
 * An analog control containing all the inputs associated with a single action
 */
class FlxControlAnalog extends FlxActionAnalog
{
    final trigger:FlxAnalogState;
    
    public function new (name, trigger, ?callback)
    {
        this.trigger = trigger;
        super(name, callback);
    }
    
    /**
     * Adds the input to this control's list
     */
    public function addInputType<TAction:EnumValue>(parent:FlxControls<TAction>, input:FlxControlInputType)
    {
        switch input
        {
            // Gamepad
            case Gamepad(Lone(id)) if (id == LEFT_TRIGGER || id == RIGHT_TRIGGER):
                addGamepadInput(id, X, parent.gamepadID);
            case Gamepad(Lone(id)) if (id == LEFT_ANALOG_STICK || id == RIGHT_ANALOG_STICK):
                addGamepadInput(id, EITHER, parent.gamepadID);
            case Gamepad(Lone(found)):
                throw 'Internal Error - Unexpected Gamepad(Digital($found))';
            case Gamepad(Multi(up, down, null, null)):
                addGamepad1D(up, down, parent.gamepadID);
            case Gamepad(Multi(up, down, right, left)):
                addGamepad2D(up, down, right, left, parent.gamepadID);
            case Gamepad(DPad)
                | Gamepad(Face)
                | Gamepad(LeftStickDigital)
                | Gamepad(RightStickDigital):
                addInputType(parent, input.simplify());
            
            // Mouse
            case Mouse(Drag(id, axis, scale, deadzone, invert)):
                add(new AnalogMouseDrag(id ?? LEFT, this.trigger, axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE));
            case Mouse(Position(axis)):
                add(new AnalogMousePosition(this.trigger, axis));
            case Mouse(Motion(axis, scale, deadzone, invert)):
                add(new AnalogMouseMove(this.trigger, axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE));
            case Mouse(Wheel(scale)):
                add(new AnalogMouseWheelDelta(this.trigger, scale ?? 0.1));
            case Mouse(Button(found)):
                throw 'Internal error - Unexpected Mouse(Button($found))';
            
            // Keys
            case Keyboard(Multi(up, down, null, null)):
                addKeys1D(up, down);
            case Keyboard(Multi(up, down, right, left)):
                addKeys2D(up, down, right, left);
            case Keyboard(Arrows)
                | Keyboard(WASD):
                addInputType(parent, input.simplify());
            case Keyboard(Lone(found)):
                throw 'Internal error - Unexpected Keyboard($found)';
            
            // VPad
            case VirtualPad(Multi(up, down, null, null)):
                @:privateAccess addVPad1D(parent.vPadProxies, up, down);
            case VirtualPad(Multi(up, down, right, left)):
                @:privateAccess addVPad2D(parent.vPadProxies, up, down, right, left);
            case VirtualPad(Arrows):
                addInputType(parent, input.simplify());
            case VirtualPad(Lone(found)):
                throw 'Internal error - Unexpected VirtualPad($found)';
        }
    }
    
    /**
     * Removes the input from this control's list
     */
    public function removeInputType(input:FlxControlInputType)
    {
        switch input
        {
            // Gamepad
            case Gamepad(Lone(id)) if (id == LEFT_TRIGGER || id == RIGHT_TRIGGER):
                removeGamepadInput(id, X);
            case Gamepad(Lone(id)) if (id == LEFT_ANALOG_STICK || id == RIGHT_ANALOG_STICK):
                removeGamepadInput(id, EITHER);
            case Gamepad(Multi(up, down, null, null)):
                removeGamepad1D(up, down);
            case Gamepad(Multi(up, down, right, left)):
                removeGamepad2D(up, down, right, left);
            case Gamepad(DPad):
                removeGamepad2D(DPAD_UP, DPAD_DOWN, DPAD_RIGHT, DPAD_LEFT);
            case Gamepad(found):
                throw 'Internal Error - Unexpected Gamepad($found)';
            
            // Mouse
            case Mouse(Drag(id, axis, _, _, _)):
                removeMouseDrag(id, axis);
            case Mouse(Position(axis)):
                removeMousePosition(axis);
            case Mouse(Motion(axis, _, _, _)):
                removeMouseMotion(axis);
            case Mouse(Wheel(_)):
                removeMouseWheel();
            case Mouse(Button(found)):
                throw 'Internal error - Unexpected Mouse(Button($found))';
            
            // Keys
            case Keyboard(Multi(up, down, null, null)):
                removeKeys1D(up, down);
            case Keyboard(Multi(up, down, right, left)):
                removeKeys2D(up, down, right, left);
            case Keyboard(Arrows):
                removeKeys2D(UP, DOWN, RIGHT, LEFT);
            case Keyboard(WASD):
                removeKeys2D(W, S, D, A);
            case Keyboard(Lone(found)):
                throw 'Internal error - Unexpected Keyboard(Lone($found))';
            
            // VPad
            case VirtualPad(Multi(up, down, null, null)):
                removeVPad1D(up, down);
            case VirtualPad(Multi(up, down, right, left)):
                removeVPad2D(up, down, right, left);
            case VirtualPad(Arrows):
                removeVPad2D(UP, DOWN, RIGHT, LEFT);
            case VirtualPad(Lone(found)):
                throw 'Internal error - Unexpected VirtualPad(Lone($found))';
        }
    }
    
    inline function addGamepadInput(inputID:FlxGamepadInputID, axis, gamepadID:FlxDeviceID
    )
    {
        add(new AnalogGamepadStick(inputID, this.trigger, axis, gamepadID.toDeviceID()));
    }
    
    function removeGamepadInput(inputID:FlxGamepadInputID, axis)
    {
        for (input in this.inputs)
        {
            if (input is AnalogGamepadStick)
            {
                final input:AnalogGamepadStick = cast input;
                if (input.inputID == inputID && input.axis == axis)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    function removeMouseMotion(axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input is AnalogMouseMove && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    function removeMousePosition(axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input is AnalogMousePosition && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    function removeMouseDrag(buttonId, axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            @:privateAccess
            if (input is AnalogMouseDrag
            && axis == input.axis
            && (cast input:AnalogMouseDrag).button == buttonId)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    function removeMouseWheel()
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input is AnalogMouseWheelDelta)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    function addKeys1D(up:FlxKey, down:FlxKey)
    {
        add(new Analog1DKeys(this.trigger, up, down));
    }
    
    function addKeys2D(up:FlxKey, down:FlxKey, right:FlxKey, left:FlxKey)
    {
        add(new Analog2DKeys(this.trigger, up, down, right, left));
    }
    
    function removeKeys1D(up:FlxKey, down:FlxKey)
    {
        for (input in this.inputs)
        {
            if (input is Analog1DKeys)
            {
                final input:Analog1DKeys = cast input;
                if (input.up == up && input.down == down)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    function removeKeys2D(up:FlxKey, down:FlxKey, right:FlxKey, left:FlxKey)
    {
        for (input in this.inputs)
        {
            if (input is Analog2DKeys)
            {
                final input:Analog2DKeys = cast input;
                if (input.up == up
                && input.down == down
                && input.right == right
                && input.left == left)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    public function addGamepad1D(up, down, gamepadID)
    {
        this.add(new Analog1DGamepad(gamepadID, this.trigger, up, down));
    }
    
    public function addGamepad2D(up, down, right, left, gamepadID)
    {
        this.add(new Analog2DGamepad(gamepadID, this.trigger, up, down, right, left));
    }
    
    public function removeGamepad1D(up, down)
    {
        for (input in this.inputs)
        {
            if (input is Analog1DGamepad)
            {
                final input:Analog1DGamepad = cast input;
                if (input.up == up && input.down == down)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    public function removeGamepad2D(up, down, right, left)
    {
        for (input in this.inputs)
        {
            if (input is Analog2DGamepad)
            {
                final input:Analog2DGamepad = cast input;
                if (input.up == up
                && input.down == down
                && input.right == right
                && input.left == left)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    function addVPad1D(proxies:VPadMap, up, down)
    {
        add(new Analog1DVPad(proxies, this.trigger, up, down));
    }
    
    function addVPad2D(proxies:VPadMap, up, down, right, left)
    {
        add(new Analog2DVPad(proxies, this.trigger, up, down, right, left));
    }
    
    function removeVPad1D(up, down)
    {
        for (input in this.inputs)
        {
            if (input is Analog1DVPad)
            {
                final input:Analog1DVPad = cast input;
                if (input.up == up && input.down == down)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    function removeVPad2D(up, down, right, left)
    {
        for (input in this.inputs)
        {
            if (input is Analog2DVPad)
            {
                final input:Analog2DVPad = cast input;
                if (input.up == up
                && input.down == down
                && input.right == right
                && input.left == left)
                {
                    this.remove(input);
                    break;
                }
            }
        }
    }
    
    public function setGamepadID(id:FlxDeviceID)
    {
        for (input in this.inputs)
        {
            if (input.device == GAMEPAD)
                input.deviceID = id.toDeviceID();
        }
    }
    
    #if (flixel < "5.9.0")
    /**
     * See if this action has been triggered
     */
    override function check()
    {
        final result = checkSuper();
        if (result && callback != null)
            callback(this);
        
        return result;
    }
    
    /**
     * avoids a bug that was fixed in 5.9.0
     */
    function checkSuper():Bool
    {
        if (_timestamp == FlxG.game.ticks)
            return triggered; // run no more than once per frame
        
        _x = null;
        _y = null;
        
        _timestamp = FlxG.game.ticks;
        triggered = false;
        
        var i = inputs != null ? inputs.length : 0;
        while (i-- > 0) // Iterate backwards, since we may remove items
        {
            final input = inputs[i];
            
            if (input.destroyed)
            {
                inputs.remove(input);
                continue;
            }
            
            input.update();
            
            if (input.check(this))
                triggered = true;
        }
        
        return triggered;
    }
    #end
}

private class ActionInputAnalog extends FlxActionInputAnalog
{
    #if (flixel < "5.9.0")
    public function new (device, inputId, trigger:FlxAnalogState, axes = EITHER, deviceId = FlxInputDeviceID.FIRST_ACTIVE)
    {
        super(device, inputId, (cast trigger:FlxInputState), axes, deviceID);
    }
    #end
}

function checkKey(key:FlxKey):Float
{
    #if FLX_KEYBOARD
    return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
    #else
    return 0.0;
    #end
}

private class Analog1DKeys extends ActionInputAnalog
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

private class Analog2DKeys extends ActionInputAnalog
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
        case FlxDeviceIDRaw.ID(id):
            final gamepad = FlxG.gamepads.getByID(id);
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxDeviceIDRaw.FIRST_ACTIVE:
            final gamepad = FlxG.gamepads.getFirstActiveGamepad();
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxDeviceIDRaw.ALL:
            FlxG.gamepads.anyPressed(id);
        case FlxDeviceIDRaw.NONE:
            false;
    }
    #else
    return false;
    #end
}

private class Analog1DGamepad extends ActionInputAnalog
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    
    public function new (gamepadID:FlxDeviceID, trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(GAMEPAD, -1, trigger, X, gamepadID.toDeviceID());
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(up, deviceID) - checkPad(down, deviceID);
        updateValues(newX, 0);
        #end
    }
}

private class AnalogGamepadStick extends FlxActionInputAnalogGamepad
{
    override function updateValues(x:Float, y:Float)
    {
        super.updateValues(x, -y);
    }
}

private class Analog2DGamepad extends ActionInputAnalog
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
        
        super(GAMEPAD, -1, trigger, EITHER, gamepadID.toDeviceID());
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(right, deviceID) - checkPad(left, deviceID);
        final newY = checkPad(up, deviceID) - checkPad(down, deviceID);
        updateValues(newX, newY);
        #end
    }
}

inline function checkVPad(id:FlxVirtualPadInputID, proxies:VPadMap):Float
{
    return proxies[id].pressed ? 1.0 : 0.0;
}


private class Analog1DVPad extends ActionInputAnalog
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

private class Analog2DVPad extends ActionInputAnalog
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

private class AnalogMouseDrag extends FlxActionInputAnalogClickAndDragMouseMotion
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

private class AnalogMouseMove extends FlxActionInputAnalogMouseMotion
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

private class AnalogMousePosition extends FlxActionInputAnalogMousePosition
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

private class AnalogMouseWheelDelta extends ActionInputAnalog
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