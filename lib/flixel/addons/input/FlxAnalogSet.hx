package flixel.addons.input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxAxes;

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
    
    public function destroy()
    {
        this.destroy();
    }
    
    public function get(action:TAction)
    {
        if (mappings.exists(action) == false)
        {
            mappings[action] = new FlxControlAnalog('${parent.name}:${action.getName()}');
            this.add(mappings[action]);
        }
        
        return mappings[action];
    }
    
    inline public function getAnalog2D(action:TAction):FlxControlAnalog2D
    {
        return cast mappings[action];
    }
    
    inline public function getAnalog1D(action:TAction):FlxControlAnalog1D
    {
        return cast mappings[action];
    }
    
    inline public function add(action:TAction, input:FlxControlInputType)
    {
        return get(action).add(input);
    }
    
    inline public function remove(action:TAction, input:FlxControlInputType)
    {
        return get(action).remove(input);
    }
}

private class FlxAnalogSetRaw<TAction:EnumValue> extends FlxActionSet
{
    public final mappings:Map<TAction, FlxControlAnalog> = [];
    
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
    
    public function add(input:FlxControlInputType)
    {
        switch input
        {
            // Gamepad
            case Gamepad(id) if (id == LEFT_TRIGGER || id == RIGHT_TRIGGER):
                addGamepadInput(id, X);
            case Gamepad(id) if (id == LEFT_ANALOG_STICK || id == RIGHT_ANALOG_STICK):
                addGamepadInput(id, EITHER);
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
    
    inline public function addGamepadInput(inputID:FlxGamepadInputID, axis)
    {
        this.addGamepad(inputID, MOVED, axis);
    }
    
    public function removeGamepadInput(inputID:FlxGamepadInputID, axis)
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
    
    inline public function addMouseMotion(axis, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.add(new AnalogMouseMove(MOVED, axis, scale, deadZone, invert));
    }
    
    public function removeMouseMotion(axis)
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
    
    inline public function addMousePosition(axis)
    {
        this.add(new AnalogMousePosition(MOVED, axis));
    }
    
    public function removeMousePosition(axis)
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
    
    inline public function addMouseDrag(buttonId, axis, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.add(new AnalogMouseDrag(buttonId, MOVED, axis, scale, deadZone, invert));
    }
    
    public function removeMouseDrag(buttonId, axis)
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
}

class AnalogMouseDrag extends FlxActionInputAnalogClickAndDragMouseMotion
{
    public function new (buttonID, trigger, axis = EITHER, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        super(buttonID, trigger, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}

class AnalogMouseMove extends FlxActionInputAnalogMouseMotion
{
    public function new (trigger, axis = EITHER, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        super(trigger, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}

class AnalogMousePosition extends FlxActionInputAnalogMousePosition
{
    public function new (trigger, axis = EITHER)
    {
        super(trigger, axis);
    }
    
    override function updateValues(x:Float, y:Float)
    {
        if (axis == Y)
            x = y;
        
        super.updateValues(x, y);
    }
}