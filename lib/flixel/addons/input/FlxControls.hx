package flixel.addons.input;

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
    
    // @:noCompletion inline function get_pressed     () { return byStatus[PRESSED      ]; }
    // @:noCompletion inline function get_released    () { return byStatus[RELEASED     ]; }
    // @:noCompletion inline function get_justPressed () { return byStatus[JUST_PRESSED ]; }
    // @:noCompletion inline function get_justReleased() { return byStatus[JUST_RELEASED]; }
    
    var byStatus = new Map<FlxInputState, FlxControlList<TAction>>();
    
    var groups:Array<Array<TAction>> = [];
    
    public function new (name:String)
    {
        this.name = name;
        super();
        
        final keyMappings = getDefaultKeyMappings();
        final gamepadMappings = getDefaultGamepadMappings();
        
        for (action => buttons in gamepadMappings)
        {
            for (button in buttons)
            {
                if (analog_inputs.contains(button))
                {
                    if (buttons.length == 1)
                        gamepadMappings.remove(action);
                    else
                        buttons.remove(button);
                    
                    //TODO: add analog stuff
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
            byStatus[status] = new FlxControlList(this, status);
            byStatus[status].initMappings(keyMappings, gamepadMappings);
            for (action in byStatus[status].mappings)
                addAction(action);
        }
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
        byStatus[status].check(action);
    }
    
    public function addKeys(action:TAction, keys:Array<FlxKey>)
    {
        for (list in byStatus)
            list.addKeys(action, keys);
    }
    
    public function addKey(action:TAction, key:FlxKey)
    {
        for (list in byStatus)
            list.addKey(action, key);
    }
    
    public function removeKeys(action:TAction, keys:Array<FlxKey>)
    {
        for (list in byStatus)
            list.removeKeys(action, keys);
    }
    
    public function removeKey(action:TAction, key:FlxKey)
    {
        for (list in byStatus)
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
        for (list in byStatus)
            list.addButtons(action, buttons);
    }
    
    public function addButton(action:TAction, button:FlxGamepadInputID)
    { 
        for (list in byStatus)
            list.addButton(action, button);
    }
    
    public function removeButtons(action:TAction, buttons:Array<FlxGamepadInputID>)
    {
        for (list in byStatus)
            list.removeButtons(action, buttons);
    }
    
    public function removeButton(action:TAction, button:FlxGamepadInputID)
    {
        for (list in byStatus)
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
@:access(flixel.addons.input.FlxControlAnalog)
abstract FlxControlAnalogStick(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    /** X axis value, or the value of a single-axis analog input */
    public var x(get, never):Float;
    inline function get_x() return this.x;
    
    /** Y axis value (If action only has single-axis input this is always == 0) */
    public var y(get, never):Float;
    inline function get_y() return this.y;
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalog(name, callback);
    }
    
    inline public function addGamepad(inputID)
    {
        this.addGamepad(inputID, MOVED, EITHER);
    }
    
    inline public function removeGamepad(inputID)
    {
        this.removeGamepad(inputID, MOVED, EITHER);
    }
}

@:forward
@:access(flixel.addons.input.FlxControlAnalog)
abstract FlxControlAnalogTrigger(FlxControlAnalog) to FlxControlAnalog to FlxActionAnalog
{
    /** The trigger value */
    public var amount(get, never):Float;
    inline function get_amount() return this.x;
    
    inline public function new (name, ?callback)
    {
        this = new FlxControlAnalog(name, callback);
    }
    
    inline public function addGamepad(inputID)
    {
        this.addGamepad(inputID, MOVED, X);
    }
    
    inline public function removeGamepad(inputID)
    {
        this.removeGamepad(inputID, MOVED, X);
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
    
    inline function addGamepad(inputID:FlxGamepadInputID, trigger, axis)
    {
        this.addGamepad(inputID, trigger, axis);
    }
    
    inline function removeGamepad(inputID:FlxGamepadInputID, trigger:FlxAnalogState, axis)
    {
        final inputs:Array<FlxActionInputAnalog> = cast this.inputs;
        for (input in inputs)
        {
            if (input.device == GAMEPAD
            && inputID == (cast input.inputID)
            && trigger == (cast input.trigger)
            && axis == input.axis)
            {
                this.remove(input);
                break;
            }
        }
    }
}