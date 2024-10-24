package flixel.addons.input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxAxes;

/**
 * Manages analog actions. There is usually only 1 of these per FlxControls instance, and it's only
 * accessed by FlxControls, which offers ways to use the actions in this set.
 */
@:forward(destroy)
abstract FlxAnalogSet<TAction:EnumValue>(FlxAnalogSetRaw<TAction>) to FlxAnalogSetRaw<TAction>
{
    var mappings(get, never):Map<TAction, FlxControlAnalog>;
    var parent(get, never):FlxControls<TAction>;
    
    function get_mappings() return this.mappings;
    function get_parent() return this.parent;
    
    public function new(parent)
    {
        this = new FlxAnalogSetRaw(parent);
    }
    
    /**
     * Retrieves the control associated with the target action
     */
    public function get(action:TAction)
    {
        if (mappings.exists(action) == false)
        {
            mappings[action] = new FlxControlAnalog('${parent.name}:${action.getName()}');
            this.add(mappings[action]);
        }
        
        return mappings[action];
    }
    
    /**
     * Retrieves the control associated with the target action
     * 
     * **Note:** Assumes the control is two-dimensional
     */
    inline public function getAnalog2D(action:TAction):FlxControlAnalog2D
    {
        return cast mappings[action];
    }
    
    /**
     * Retrieves the control associated with the target action
     * 
     * **Note:** Assumes the control is one-dimensional
     */
    inline public function getAnalog1D(action:TAction):FlxControlAnalog1D
    {
        return cast mappings[action];
    }
    
    /**
     * Registers the control associated with the target action
     */
    inline public function add(action:TAction, input:FlxControlInputType)
    {
        return get(action).add(parent, input);
    }
    
    /**
     * Unregisters the control associated with the target action
     */
    inline public function remove(action:TAction, input:FlxControlInputType)
    {
        return get(action).remove(input);
    }
    
    function setGamepadID(id:FlxGamepadID)
    {
        for (control in mappings)
            control.setGamepadID(id);
    }
}

private class FlxAnalogSetRaw<TAction:EnumValue> extends FlxActionSet
{
    /**
     * The map of actions to controls, used by `FlxAnalogSet`
     */
    public final mappings:Map<TAction, FlxControlAnalog> = [];
    
    /**
     * The controlling instance
     */
    public var parent:FlxControls<TAction>;
    
    public function new(parent)
    {
        this.parent = parent;
        
        super('${parent.name}:analog-list');
    }
    
    override function destroy()
    {
        parent = null;
        mappings.clear();
    }
}

abstract FlxControlAnalog2D(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    /** X axis value */
    public var x(get, never):Float;
    inline function get_x() return this.x;
    
    /** Y axis value */
    public var y(get, never):Float;
    inline function get_y() return this.y;
}

abstract FlxControlAnalog1D(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    /** The analog value */
    public var value(get, never):Float;
    inline function get_value() return this.x;
}

private class FlxControlAnalogRaw extends FlxActionAnalog
{
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

/**
 * An analog control containing all the inputs associated with a single action
 */
@:forward(x, y)
// private 
abstract FlxControlAnalog(FlxControlAnalogRaw) to FlxControlAnalogRaw
{
    // public var moved(get, never):Bool // TODO:
    // inline function get_moved():Bool return true; // TODO:
    
    // public var justMoved(get, never):Bool // TODO:
    // inline function justMoved():Bool return true; // TODO:
    
    // public var stopped(get, never):Bool // TODO:
    // inline function get_stopped():Bool return true; // TODO:
    
    // public var justStopped(get, never):Bool // TODO:
    // inline function get_justStopped():Bool return true; // TODO:
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalogRaw(name, callback);
    }
    
    /**
     * Adds the input to this control's list
     */
    public function add<TAction:EnumValue>(parent:FlxControls<TAction>, input:FlxControlInputType)
    {
        switch input
        {
            // Gamepad
            case Gamepad(id) if (id == LEFT_TRIGGER || id == RIGHT_TRIGGER):
                addGamepadInput(id, X, parent.gamepadID);
            case Gamepad(id) if (id == LEFT_ANALOG_STICK || id == RIGHT_ANALOG_STICK):
                addGamepadInput(id, EITHER, parent.gamepadID);
            case Gamepad(found):
                throw 'Internal Error - Unexpected Gamepad($found)';
            
            // Mouse
            case Mouse(Drag(id, axis, scale, deadzone, invert)):
                addMouseDrag(id ?? LEFT, axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE);
            case Mouse(Position(axis)):
                addMousePosition(axis);
            case Mouse(Motion(axis, scale, deadzone, invert)):
                addMouseMotion(axis ?? EITHER, scale ?? 0.1, deadzone ?? 0.1, invert ?? FlxAxes.NONE);
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
    public function remove(input:FlxControlInputType)
    {
        switch input
        {
            // Gamepad
            case Gamepad(id) if (id == LEFT_TRIGGER || id == RIGHT_TRIGGER):
                removeGamepadInput(id, X);
            case Gamepad(id) if (id == LEFT_ANALOG_STICK || id == RIGHT_ANALOG_STICK):
                removeGamepadInput(id, EITHER);
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
            case Keyboard(found):
                throw 'Internal error - Unexpected Keyboard($found)';
        }
    }
    
    inline function addGamepadInput(inputID:FlxGamepadInputID, axis, gamepadID:FlxGamepadID)
    {
        this.addGamepad(inputID, MOVED, axis, gamepadID.toDeviceID());
    }
    
    function removeGamepadInput(inputID:FlxGamepadInputID, axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input.device == GAMEPAD
            && inputID == (cast input.inputID)
            && MOVED == (cast input.trigger)
            && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    inline function addMouseMotion(axis, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.add(new AnalogMouseMove(MOVED, axis, scale, deadZone, invert));
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
    
    inline function addMousePosition(axis)
    {
        this.add(new AnalogMousePosition(MOVED, axis));
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
    
    inline function addMouseDrag(buttonId, axis, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.add(new AnalogMouseDrag(buttonId, MOVED, axis, scale, deadZone, invert));
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
    
    public function addKeys1D(up:FlxKey, down:FlxKey)
    {
        this.add(new Analog1DKeys(this.trigger, up, down));
    }
    
    public function addKeys2D(up:FlxKey, down:FlxKey, right:FlxKey, left:FlxKey)
    {
        this.add(new Analog2DKeys(this.trigger, up, down, right, left));
    }
    
    public function removeKeys1D(up:FlxKey, down:FlxKey)
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
    
    public function removeKeys2D(up:FlxKey, down:FlxKey, right:FlxKey, left:FlxKey)
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
    
    public function setGamepadID(id:FlxGamepadID)
    {
        for (input in this.inputs)
        {
            if (input.device == GAMEPAD)
                input.deviceID = id.toDeviceID();
        }
    }
}

private class Analog1DKeys extends FlxActionInputAnalog
{
    public var up:FlxKey;
    public var down:FlxKey;
    
    public function new (trigger:FlxAnalogState, up:FlxKey, down:FlxKey)
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
    
    function checkKey(key:FlxKey):Float
    {
        return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
    }
}

private class Analog2DKeys extends FlxActionInputAnalog
{
    public var up:FlxKey;
    public var down:FlxKey;
    public var right:FlxKey;
    public var left:FlxKey;
    
    public function new (trigger:FlxAnalogState, up:FlxKey, down:FlxKey, right:FlxKey, left:FlxKey)
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
        updateValues(newX, newY);
        #end
    }
    
    function checkKey(key:FlxKey):Float
    {
        return FlxG.keys.checkStatus(key, PRESSED) ? 1.0 : 0.0;
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