package flixel.addons.input;

import haxe.ds.ReadOnlyArray;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

enum Device
{
    Keys;
    Gamepad(id:Int);
}

abstract class FlxControls<TAction:EnumValue> extends FlxActionSet
{
    static final all_states:ReadOnlyArray<FlxInputState> = [PRESSED, RELEASED, JUST_PRESSED, JUST_RELEASED];
    
    var pressedList     (get, never):FlxControlList<TAction>;
    var releasedList    (get, never):FlxControlList<TAction>;
    var justPressedList (get, never):FlxControlList<TAction>;
    var justReleasedList(get, never):FlxControlList<TAction>;
    
    inline function get_pressedList     () { return byStatus[PRESSED      ]; }
    inline function get_releasedList    () { return byStatus[RELEASED     ]; }
    inline function get_justPressedList () { return byStatus[JUST_PRESSED ]; }
    inline function get_justReleasedList() { return byStatus[JUST_RELEASED]; }
    
    inline public function pressed     (action:TAction) { return pressedList     .check(action); }
    inline public function released    (action:TAction) { return releasedList    .check(action); }
    inline public function justPressed (action:TAction) { return justPressedList .check(action); }
    inline public function justReleased(action:TAction) { return justReleasedList.check(action); }
    
    inline public function anyPressed     (actions:Array<TAction>) { return pressedList     .any(actions); }
    inline public function anyReleased    (actions:Array<TAction>) { return releasedList    .any(actions); }
    inline public function anyJustPressed (actions:Array<TAction>) { return justPressedList .any(actions); }
    inline public function anyJustReleased(actions:Array<TAction>) { return justReleasedList.any(actions); }
    
    var byStatus = new Map<FlxInputState, FlxControlList<TAction>>();
    
    var groups:Array<Array<TAction>> = [];
    
    public function new (name:String)
    {
        super(name);
        
        final keys = getDefaultKeyMappings();
        final buttons = getDefaultButtonMappings();
        
        for (action in keys.keys())
        {
            if (buttons.exists(action) == false)
                buttons[action] = null;
        }
        
        for (action in buttons.keys())
        {
            if (keys.exists(action) == false)
                keys[action] = null;
        }
        
        for (status in all_states)
        {
            byStatus[status] = new FlxControlList(this, status);
            byStatus[status].initMappings(keys, buttons);
            for (action in byStatus[status].mappings)
                add(action);
        }
    }
    
    abstract function getDefaultKeyMappings():Map<TAction, Null<Array<FlxKey>>>;
    abstract function getDefaultButtonMappings():Map<TAction, Null<Array<FlxGamepadInputID>>>;
    
    public function checkStatus(action:TAction, status:FlxInputState)
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


// @:genericBuild(flixel.addons.system.macros.FlxControlsMacro.generateControlFields())
class FlxControlList<TAction:EnumValue> extends FlxControlListBase<TAction> {}

@:allow(flixel.addons.input.FlxControls)
class FlxControlListBase<TAction:EnumValue>
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
            final mapping = addMapping(action);
            
            if (keys[action] != null)
               mapping.addKeys(keys[action], status);
            
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


@:allow(flixel.addons.input.FlxControlListBase)
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