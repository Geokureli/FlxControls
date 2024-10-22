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
    // Add overides here
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
            
            // Misc
            case VirtualPad(found):
                throw 'Internal error - Unexpected VirtualPad($found)';
            case Keyboard(found):
                throw 'Internal error - Unexpected Keyboard($found)';
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
            
            // Misc
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
    
    public function setGamepadID(id:FlxGamepadID)
    {
        for (input in this.inputs)
        {
            if (input.device == GAMEPAD)
                input.deviceID = id.toDeviceID();
        }
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