package flixel.addons.input;

import flixel.util.FlxAxes;
import flixel.util.typeLimit.OneOfTwo;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import haxe.ds.ReadOnlyArray;

enum Device
{
    Keys;
    Gamepad(id:Int);
}

enum GamepadInput
{
    DIGITAL(id:FlxGamepadInputID);
    ANALOG_XY(id:FlxGamepadInputID, ?unit:Int, ?deadZone:Float, ?invert:FlxAxes);
    ANALOG(id:FlxGamepadInputID, ?unit:Int, ?deadZone:Float, ?invert:FlxAxes);
}

typedef ActionMap<TAction, TInput> = Map<TAction, Null<Array<TInput>>>;

@:autoBuild(flixel.addons.system.macros.FlxControlsMacro.buildControls())
abstract class FlxControls<TAction:EnumValue> extends FlxActionManager
{
    static final all_states:ReadOnlyArray<FlxInputState> = [PRESSED, RELEASED, JUST_PRESSED, JUST_RELEASED];
    static final analog_inputs:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    
    public var activeGamepad(default, null):Null<FlxGamepad>;
    public var name(default, null):String;
    
    // These fields are generated via macro
    // public var pressed     (get, never):FlxControlList<TAction>;
    // public var released    (get, never):FlxControlList<TAction>;
    // public var justPressed (get, never):FlxControlList<TAction>;
    // public var justReleased(get, never):FlxControlList<TAction>;
    
    // @:noCompletion inline function get_pressed     () { return listsByStatus[PRESSED      ]; }
    // @:noCompletion inline function get_released    () { return listsByStatus[RELEASED     ]; }
    // @:noCompletion inline function get_justPressed () { return listsByStatus[JUST_PRESSED ]; }
    // @:noCompletion inline function get_justReleased() { return listsByStatus[JUST_RELEASED]; }
    
    final listsByStatus = new Map<FlxInputState, FlxControlList<TAction>>();
    
    /** Used internally to get various analog actions */
    final analogs = new Map<TAction, FlxControlAnalog>();
    
    /** Used internally to list sets of actions that cannot have conflicting inputs */
    final groups:Map<String, Array<TAction>> = [];
    
    public function new (name:String)
    {
        this.name = name;
        super();
        
        final keyMappings = getDefaultKeyMappings();
        final gamepadMappings = getDefaultGamepadMappings();
        
        for (action => inputs in gamepadMappings)
        {
            for (input in inputs)
            {
                if (analog_inputs.contains(input))
                {
                    if (inputs.length == 1)
                        gamepadMappings.remove(action);
                    else
                        inputs.remove(input);
                    
                    final analog:FlxControlAnalog = switch(input)
                    {
                        case LEFT_TRIGGER | RIGHT_TRIGGER:
                            final analog = new FlxControlAnalog1D(action.getName());
                            analog.addGamepad(input);
                            analog;
                        case LEFT_ANALOG_STICK | RIGHT_ANALOG_STICK:
                            final analog = new FlxControlAnalog2D(action.getName());
                            analog.addGamepad(input);
                            analog;
                        case found:
                            throw 'Unexpected input: $found';
                    }
                    analogs[action] = analog;
                    addAction(analog);
                }
            }
        }
        
        // for (action in keyMappings.keys())
        // {
        //     if (gamepadMappings.exists(action) == false)
        //         gamepadMappings[action] = null;
        // }
        
        // for (action in gamepadMappings.keys())
        // {
        //     if (keyMappings.exists(action) == false)
        //         keyMappings[action] = null;
        // }
        
        for (status in all_states)
        {
            listsByStatus[status] = new FlxControlList(this, status);
            listsByStatus[status].initMappings(keyMappings, gamepadMappings);
            for (action in listsByStatus[status].mappings)
                addAction(action);
        }
        
        initGroups();
    }
    
    function initGroups() {}
    
    override function destroy()
    {
        super.destroy();
        
        for (list in listsByStatus)
            list.destroy();
        
        // for (analog in analogs)
        //     analog.destroy();
        
        listsByStatus.clear();
        analogs.clear();
    }
    
    inline public function getJoystick(action:TAction):FlxControlAnalog2D
    {
        return cast analogs[action];
    }
    
    inline public function getTrigger(action:TAction):FlxControlAnalog1D
    {
        return cast analogs[action];
    }
    
    public function setGamepad(gamepad:FlxGamepad)
    {
        if (activeGamepad == gamepad)
            return;
        
        if (activeGamepad != null)
            removeActiveGamepad();
        
        activeGamepad = gamepad;
        
        for (action in defaultSet.digitalActions)
        {
            for (input in action.inputs)
            {
                if (input.device == GAMEPAD)
                {
                    input.deviceID = gamepad.id;
                }
            }
        }
    }
    
    public function removeActiveGamepad()
    {
        for (action in defaultSet.digitalActions)
        {
            for (input in action.inputs)
            {
                if (input.device == GAMEPAD)
                {
                    input.deviceID = FlxInputDeviceID.NONE;
                }
            }
        }
    }
    
    abstract function getDefaultKeyMappings():ActionMap<TAction, FlxKey>;
    abstract function getDefaultGamepadMappings():ActionMap<TAction, FlxGamepadInputID>;
    // abstract function attachVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    // abstract function createVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    
    inline public function checkStatus(action:TAction, status:FlxInputState)
    {
        listsByStatus[status].check(action);
    }
    
    public function addKeys(action:TAction, keys:Array<FlxKey>)
    {
        for (list in listsByStatus)
            list.addKeys(action, keys);
    }
    
    public function addKey(action:TAction, key:FlxKey)
    {
        for (list in listsByStatus)
            list.addKey(action, key);
    }
    
    public function removeKeys(action:TAction, keys:Array<FlxKey>)
    {
        for (list in listsByStatus)
            list.removeKeys(action, keys);
    }
    
    public function removeKey(action:TAction, key:FlxKey)
    {
        for (list in listsByStatus)
            list.removeKey(action, key);
    }
    
    public function replaceKey(action:TAction, ?oldKey:FlxKey, ?newKey:FlxKey)
    {
        if (oldKey != null)
            removeKey(action, oldKey);
        
        if (newKey != null)
            addKey(action, newKey);
    }
    
    public function addButtons(action:TAction, buttons:Array<FlxGamepadInputID>)
    {
        for (list in listsByStatus)
            list.addButtons(action, buttons);
    }
    
    public function addButton(action:TAction, button:FlxGamepadInputID)
    { 
        for (list in listsByStatus)
            list.addButton(action, button);
    }
    
    public function removeButtons(action:TAction, buttons:Array<FlxGamepadInputID>)
    {
        for (list in listsByStatus)
            list.removeButtons(action, buttons);
    }
    
    public function removeButton(action:TAction, button:FlxGamepadInputID)
    {
        for (list in listsByStatus)
            list.removeButton(action, button);
    }
    
    public function replaceButton(action:TAction, ?oldButton:FlxGamepadInputID, ?newButton:FlxGamepadInputID)
    {
        if (oldButton != null)
            removeButton(action, oldButton);
        
        if (newButton != null)
            addButton(action, newButton);
    }
}

@:allow(flixel.addons.input.FlxControls)
class FlxControlList<TAction:EnumValue>
{
    final status:FlxInputState;
    var parent:FlxControls<TAction>;
    
    var mappings:Map<TAction, FlxControlDigital> = [];
    
    function new(parent, status)
    {
        this.parent = parent;
        this.status = status;
    }
    
    function destroy()
    {
        parent = null;
        mappings.clear();
    }
    
    function initMappings(keys:Map<TAction, Null<Array<FlxKey>>>, buttons:Map<TAction, Null<Array<FlxGamepadInputID>>>)
    {
        mappings.clear();
        
        for (action in keys.keys())
        {
            final mapping = getMapping(action);
            
            if (keys[action] != null)
               mapping.addKeys(keys[action], status);
        }
        
        for (action in buttons.keys())
        {
            final mapping = getMapping(action);
            
            if (buttons[action] != null)
               mapping.addButtons(buttons[action], status);
        }
    }
    
    function get(action:TAction)
    {
        if (mappings.exists(action) == false)
            return addMapping(action);
        
        return mappings[action];
    }
    
    inline public function check(action:TAction)
    {
        return get(action).check();
    }
    
    public function any(actions:Array<TAction>)
    {
        for (action in actions)
        {
            if (get(action).check())
                return true;
        }
        return false;
    }
    
    function getMapping(action:TAction)
    {
        if (mappings.exists(action) == false)
            addMapping(action);
        
        return mappings[action];
    }
    
    inline function addMapping(action:TAction)
    {
        return mappings[action] = new FlxControlDigital('${parent.name}:${action.getName()}-$status');
    }
    
    inline function addKeys(action:TAction, keys:Array<FlxKey>)
    {
        return get(action).addKeys(keys, status);
    }
    
    inline function addKey(action:TAction, key:FlxKey)
    {
        return get(action).addKey(key, status);
    }
    
    inline function removeKeys(action:TAction, keys:Array<FlxKey>)
    {
        return get(action).removeKeys(keys, status);
    }
    
    inline function removeKey(action:TAction, key:FlxKey)
    {
        return get(action).removeKey(key, status);
    }
    
    inline function addButtons(action:TAction, buttons:Array<FlxGamepadInputID>)
    {
        return get(action).addButtons(buttons, status);
    }
    
    inline function addButton(action:TAction, button:FlxGamepadInputID)
    {
        return get(action).addButton(button, status);
    }
    
    inline function removeButtons(action:TAction, buttons:Array<FlxGamepadInputID>)
    {
        return get(action).removeButtons(buttons, status);
    }
    
    inline function removeButton(action:TAction, button:FlxGamepadInputID)
    {
        return get(action).removeButton(button, status);
    }
}


@:allow(flixel.addons.input.FlxControlList)
abstract FlxControlDigital(FlxActionDigital) to FlxActionDigital
{
    function new (name, ?callback)
    {
        this = new FlxActionDigital(name, callback);
    }
    
    inline function check() return this.check();
    
    function addKey(keys:FlxKey, status:FlxInputState)
    {
        return this.addKey(keys, status);
    }
    
    function addKeys(keys:Array<FlxKey>, status:FlxInputState)
    {
        for (key in keys)
            addKey(key, status);
    }
    
    function removeKeys(keys:Array<FlxKey>, status:FlxInputState)
    {
        var i = this.inputs.length;
        while (i-- > 0)
        {
            final input = this.inputs[i];
            if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
                this.remove(input);
        }
    }
    
    function removeKey(key:FlxKey, status:FlxInputState)
    {
        for (input in this.inputs)
        {
            if (input.device == KEYBOARD && key == cast input.inputID)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    function addButtons(buttons:Array<FlxGamepadInputID>, status:FlxInputState)
    {
        for (button in buttons)
            addButton(button, status);
    }
    
    inline function addButton(button:FlxGamepadInputID, status:FlxInputState)
    {
        this.addGamepad(button, status);
    }
    
    function removeButtons(buttons:Array<FlxGamepadInputID>, status:FlxInputState)
    {
        var i = this.inputs.length;
        while (i-- > 0)
        {
            final input = this.inputs[i];
            if (input.device == GAMEPAD && buttons.indexOf(cast input.inputID) != -1)
                this.remove(input);
        }
    }
    
    function removeButton(button:FlxGamepadInputID, status:FlxInputState)
    {
        for (input in this.inputs)
        {
            if (input.device == GAMEPAD && button == cast input.inputID)
            {
                this.remove(input);
                break;
            }
        }
    }
}

@:allow(flixel.addons.input.FlxControls)
class FlxControlAnalogList<TAction:EnumValue>
{
    final status:FlxInputState;
    var parent:FlxControls<TAction>;
    
    var mappings:Map<TAction, FlxControlAnalog> = [];
    
    function new(parent, status)
    {
        this.parent = parent;
        this.status = status;
    }
    
    function destroy()
    {
        parent = null;
        mappings.clear();
    }
    
    function initMappings(buttons:Map<TAction, Null<Array<FlxGamepadInputID>>>)
    {
        mappings.clear();
        
        for (action in buttons.keys())
        {
            final mapping = getMapping(action);
            
            // if (buttons[action] != null)
            //    mapping.addGamepad(buttons[action], status);
        }
    }
    
    function getMapping(action:TAction)
    {
        if (mappings.exists(action) == false)
            addMapping(action);
        
        return mappings[action];
    }
    
    inline function addMapping(action:TAction)
    {
        return mappings[action] = new FlxControlAnalog('${parent.name}:${action.getName()}-$status');
    }
    
    function get(action:TAction)
    {
        if (mappings.exists(action) == false)
            return addMapping(action);
        
        return mappings[action];
    }
    
    // inline public function check(action:TAction):Float
    // {
    //     return get(action).check();
    // }
    
}

@:forward
@:access(flixel.addons.input.FlxControlAnalogBase2D)
abstract FlxControlAnalog2D(FlxControlAnalogBase2D) to FlxControlAnalogBase2D to FlxControlAnalog to FlxActionAnalog
{
    /** X axis value, or the value of a single-axis analog input */
    public var x(get, never):Float;
    inline function get_x() return this.getX();
    
    /** Y axis value (If action only has single-axis input this is always == 0) */
    public var y(get, never):Float;
    inline function get_y() return this.getY();
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalogBase2D(name, callback);
    }
}

@:access(flixel.addons.input.FlxControlAnalog)
abstract FlxControlAnalogBase2D(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalog(name, callback);
    }
    
    inline function getX():Float { return this.x; }
    inline function getY():Float { return this.y; }
    
    inline public function addGamepad(inputID)
    {
        this.addGamepad(inputID, EITHER);
    }
    
    inline public function removeGamepad(inputID)
    {
        this.removeGamepad(inputID, EITHER);
    }
    
    inline public function addMouseMotion(unit = 10, deadZone = 0.1, invert = false)
    {
        this.addMouseMotion(EITHER, unit, deadZone, invert);
    }
    
    inline public function removeMouseMotion()
    {
        this.removeMouseMotion(EITHER);
    }
    
    inline public function addMousePosition()
    {
        this.addMousePosition(EITHER);
    }
    
    inline public function removeMousePosition()
    {
        this.removeMousePosition(EITHER);
    }
    
    inline public function addMouseDrag(buttonId, unit = 10, deadZone = 0.1, invertY = false, invertX = false)
    {
        this.addMouseDrag(buttonId, EITHER, unit, deadZone, invertY, invertX);
    }
    
    inline public function removeMouseDrag(buttonId)
    {
        this.removeMouseDrag(buttonId, EITHER);
    }
}

@:forward
@:access(flixel.addons.input.FlxControlAnalogBase1D)
abstract FlxControlAnalog1D(FlxControlAnalogBase1D) to FlxControlAnalogBase1D to FlxControlAnalog to FlxActionAnalog
{
    /** The trigger value */
    public var amount(get, never):Float;
    inline function get_amount() return this.getX();
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalogBase1D(name, callback);
    }
}
@:access(flixel.addons.input.FlxControlAnalog)
abstract FlxControlAnalogBase1D(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    /** The analog value */
    inline function getX() return this.x;
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalog(name, callback);
    }
    
    inline public function addGamepad(inputID)
    {
        this.addGamepad(inputID, X);
    }
    
    inline public function removeGamepad(inputID)
    {
        this.removeGamepad(inputID, X);
    }
    
    inline public function addMouseX()
    {
        this.addMousePosition(X);
    }
    
    inline public function addMouseY()
    {
        this.addMousePosition(Y);
    }
    
    inline public function removeMouseX()
    {
        this.removeMousePosition(X);
    }
    
    inline public function removeMouseY()
    {
        this.removeMousePosition(Y);
    }
}

@:allow(flixel.addons.input.FlxControlAnalogList)
abstract FlxControlAnalog(FlxActionAnalog) to FlxActionAnalog
{
    /** X axis value, or the value of a single-axis analog input */
    var x(get, never):Float;
    inline function get_x() return this.x;
    
    /** Y axis value (If action only has single-axis input this is always == 0) */
    var y(get, never):Float;
    inline function get_y() return this.y;
    
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
        this = new FlxActionAnalog(name, callback);
    }
    
    inline function addGamepad(inputID:FlxGamepadInputID, axis)
    {
        removeGamepad(inputID, axis);
        this.addGamepad(inputID, MOVED, axis);
    }
    
    function removeGamepad(inputID:FlxGamepadInputID, axis)
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
    
    inline function addMouseMotion(axis, unit = 10, deadZone = 0.1, invertY = false, invertX = false)
    {
        removeMouseMotion(axis);
        this.addMouseMotion(MOVED, axis, unit, deadZone, invertY, invertX);
    }
    
    function removeMouseMotion(axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input is FlxActionInputAnalogMouseMotion && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    inline function addMousePosition(axis)
    {
        removeMousePosition(axis);
        this.addMousePosition(MOVED, axis);
    }
    
    function removeMousePosition(axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input is FlxActionInputAnalogMousePosition && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
    
    inline function addMouseDrag(buttonId, axis, unit = 10, deadZone = 0.1, invertY = false, invertX = false)
    {
        removeMouseDrag(buttonId, axis);
        this.addMouseClickAndDragMotion(buttonId, MOVED, axis, unit, deadZone, invertY, invertX);
    }
    
    function removeMouseDrag(buttonId, axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            @:privateAccess
            if (input is FlxActionInputAnalogClickAndDragMouseMotion
            && axis == input.axis
            && (cast input:FlxActionInputAnalogClickAndDragMouseMotion).button == buttonId)
            {
                this.remove(input);
                break;
            }
        }
    }
}