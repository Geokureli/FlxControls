package flixel.addons.input;

import flixel.input.FlxInput;
import flixel.util.FlxDirection;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxAxes;

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
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` is positive, `pressed.up` will be `true`
     */
    public var pressed(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_pressed() return this.pressed;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` just became positive, `justPressed.up` will be `true`
     */
    public var justPressed(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_justPressed() return this.justPressed;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` is `0` or negative, `released.up` will be `true`
     */
    public var released(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_released() return this.released;
    
    /**
     * Helper for extracting digital directional states from a 2D analog action.
     * For instance, if the action's `y` just became `0` or negative, `justReleased.up` will be `true`
     */
    public var justReleased(get, never):FlxAnalogDirections1D<TAction>;
    inline function get_justReleased() return this.justReleased;
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
    
    var upInput = new FlxInput<FlxDirection>(UP);
    var downInput = new FlxInput<FlxDirection>(DOWN);
    var leftInput = new FlxInput<FlxDirection>(LEFT);
    var rightInput = new FlxInput<FlxDirection>(RIGHT);
    
    var control:FlxControlAnalog;
    var parent:FlxControls<TAction>;
    var name:String;
    
    function new(parent, action:TAction)
    {
        this.parent = parent;
        final namePrefix = '${parent.name}:${action.getName()}';
        name = '$namePrefix-analogSet';
        control = new FlxControlAnalog('$namePrefix-control', MOVED);
        
        pressed      = new FlxAnalogDirections2D(this, PRESSED      );
        released     = new FlxAnalogDirections2D(this, RELEASED     );
        justPressed  = new FlxAnalogDirections2D(this, JUST_PRESSED );
        justReleased = new FlxAnalogDirections2D(this, JUST_RELEASED);
    }
    
    function destroy()
    {
        parent = null;
        
        pressed.destroy();
        justPressed.destroy();
        released.destroy();
        justReleased.destroy();
    }
    
    function update()
    {
        control.update();
        
        upInput.update();
        if (control.y > 0 && upInput.released) upInput.press();
        if (control.y <= 0 && upInput.pressed) upInput.release();
        
        downInput.update();
        if (control.y < 0 && downInput.released) downInput.press();
        if (control.y >= 0 && downInput.pressed) downInput.release();
        
        rightInput.update();
        if (control.x > 0 && rightInput.released) rightInput.press();
        if (control.x <= 0 && rightInput.pressed) rightInput.release();
        
        leftInput.update();
        if (control.x < 0 && leftInput.released) leftInput.press();
        if (control.x >= 0 && leftInput.pressed) leftInput.release();
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
    
    function setGamepadID(id:FlxGamepadID)
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
    function get_up() return set.upInput.hasState(state);
    
    /** The digital down component of this 2D action **/
    public var down(get, never):Bool;
    function get_down() return set.downInput.hasState(state);
    
    /** The digital left component of this 2D action **/
    public var left(get, never):Bool;
    function get_left() return set.leftInput.hasState(state);
    
    /** The digital right component of this 2D action **/
    public var right(get, never):Bool;
    function get_right() return set.rightInput.hasState(state);
    
    var set:FlxAnalogSet<TAction>;
    final state:FlxInputState;
    
    function new(set, state)
    {
        this.set = set;
        this.state = cast state;
    }
    
    function destroy()
    {
        this.set = null;
    }
    
    public function toString()
    {
        return '( u: $up | d: $down | l: $left | r: $right)';
    }
}

/**
 * An analog control containing all the inputs associated with a single action
 */
class FlxControlAnalog extends FlxActionAnalog
{
    var trigger:FlxAnalogState;
    
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
            
            // Mouse
            case Mouse(Drag(id, axis, scale, deadzone, invert)):
                add(new AnalogMouseDrag(id ?? LEFT, this.trigger, axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE));
            case Mouse(Position(axis)):
                add(new AnalogMousePosition(this.trigger, axis));
            case Mouse(Motion(axis, scale, deadzone, invert)):
                add(new AnalogMouseMove(this.trigger, axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE));
            case Mouse(Button(found)):
                throw 'Internal error - Unexpected Mouse(Button($found))';
            
            // Keys
            case Keyboard(Multi(up, down, null, null)):
                addKeys1D(up, down);
            case Keyboard(Multi(up, down, right, left)):
                addKeys2D(up, down, right, left);
            case Keyboard(Lone(found)):
                throw 'Internal error - Unexpected Keyboard($found)';
            
            // VPad
            case VirtualPad(found):
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
            case Gamepad(found):
                throw 'Internal Error - Unexpected Gamepad($found)';
            
            // Mouse
            case Mouse(Drag(id, axis, _, _, _)):
                removeMouseDrag(id, axis);
            case Mouse(Position(axis)):
                removeMousePosition(axis);
            case Mouse(Motion(axis, _, _, _)):
                removeMouseMotion(axis);
            case Mouse(Button(found)):
                throw 'Internal error - Unexpected Mouse(Button($found))';
            
            // Keys
            case Keyboard(Multi(up, down, null, null)):
                removeKeys1D(up, down);
            case Keyboard(Multi(up, down, right, left)):
                removeKeys2D(up, down, right, left);
            case Keyboard(Lone(found)):
                throw 'Internal error - Unexpected Keyboard($found)';
            
            // VPad
            case VirtualPad(found):
                throw 'Internal error - Unexpected VirtualPad($found)';
        }
    }
    
    inline function addGamepadInput(inputID:FlxGamepadInputID, axis, gamepadID:FlxGamepadID)
    {
        addGamepad(inputID, this.trigger, axis, gamepadID.toDeviceID());
    }
    
    function removeGamepadInput(inputID:FlxGamepadInputID, axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input.device == GAMEPAD
            && inputID == (cast input.inputID)
            && this.trigger == (cast input.trigger)
            && axis == input.axis)
            {
                this.remove(input);
                break;
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
    
    public function setGamepadID(id:FlxGamepadID)
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

function checkKey(key:FlxKey):Float
{
    return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
}

private class Analog1DKeys extends FlxActionInputAnalog
{
    public var up:FlxKey;
    public var down:FlxKey;
    
    public function new (trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(KEYBOARD, -1, cast trigger, X);
    }
    
    override function update()
    {
        #if FLX_KEYBOARD
        final newX = checkKey(up) - checkKey(down);
        updateValues(newX, 0);
        #end
    }
}

private class Analog2DKeys extends FlxActionInputAnalog
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
        
        super(KEYBOARD, -1, cast trigger, EITHER);
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

inline function checkPad(id:FlxGamepadInputID, gamepadID:FlxGamepadID):Float
{
    return checkPadBool(id, gamepadID) ? 1.0 : 0.0;
}

function checkPadBool(id:FlxGamepadInputID, gamepadID:FlxGamepadID):Bool
{
    return switch gamepadID
    {
        case FlxGamepadIDRaw.ID(id):
            final gamepad = FlxG.gamepads.getByID(id);
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxGamepadIDRaw.FIRST_ACTIVE:
            final gamepad = FlxG.gamepads.getFirstActiveGamepad();
            gamepad != null && gamepad.checkStatus(id, PRESSED);
        case FlxGamepadIDRaw.ALL:
            FlxG.gamepads.anyPressed(id);
        case FlxGamepadIDRaw.NONE:
            false;
    }
}

private class Analog1DGamepad extends FlxActionInputAnalog
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    
    public function new (gamepadID:FlxGamepadID, trigger:FlxAnalogState, up, down)
    {
        this.up = up;
        this.down = down;
        super(GAMEPAD, -1, cast trigger, X, gamepadID.toDeviceID());
    }
    
    override function update()
    {
        #if FLX_KEYBOARD
        final newX = checkPad(up, deviceID) - checkPad(down, deviceID);
        updateValues(newX, 0);
        #end
    }
}

private class Analog2DGamepad extends FlxActionInputAnalog
{
    public var up:FlxGamepadInputID;
    public var down:FlxGamepadInputID;
    public var right:FlxGamepadInputID;
    public var left:FlxGamepadInputID;
    
    public function new (gamepadID:FlxGamepadID, trigger:FlxAnalogState, up, down, right, left)
    {
        this.up = up;
        this.down = down;
        this.right = right;
        this.left = left;
        
        super(GAMEPAD, -1, cast trigger, EITHER, gamepadID.toDeviceID());
    }
    
    override function update()
    {
        #if FLX_GAMEPAD
        final newX = checkPad(right, deviceID) - checkPad(left, deviceID);
        final newY = checkPad(up, deviceID) - checkPad(down, deviceID);
        updateValues(newX, newY);
        #end
    }
    
    override function check(action)
	{
		final result = super.check(action);
        if (result)
            FlxG.watch.addQuick('gpad2d', '( x: $x | y: $y )');
        
        return result;
	}
}

private class AnalogMouseDrag extends FlxActionInputAnalogClickAndDragMouseMotion
{
    public function new (buttonID, trigger, axis = EITHER, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        // If only tracking y, set x to y, because 1d controls always check x
        super(buttonID, trigger, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
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
    public function new (trigger, axis = EITHER, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        super(trigger, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
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