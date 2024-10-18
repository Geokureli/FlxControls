package flixel.addons.input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.FlxInput;
import flixel.input.IFlxInput;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseButton;


@:allow(flixel.addons.input.FlxControls)
abstract FlxDigitalSet<TAction:EnumValue>(FlxDigitalSetRaw<TAction>) to FlxDigitalSetRaw<TAction>
{
    var state(get, never):FlxInputState;
    var mappings(get, never):Map<TAction, FlxControlDigital>;
    var parent(get, never):FlxControls<TAction>;
    
    function get_state() return this.state;
    function get_mappings() return this.mappings;
    function get_parent() return this.parent;
    
    inline public function new (parent, state)
    {
        this = new FlxDigitalSetRaw(parent, state);
    }
    
    public function destroy()
    {
        this.destroy();
    }
    
    function get(action:TAction)
    {
        if (mappings.exists(action) == false)
        {
            mappings[action] = new FlxControlDigital('${parent.name}:${action.getName()}-$state');
            this.add(mappings[action]);
        }
        
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
    
    inline function add(action:TAction, input:FlxControlInputType)
    {
        return get(action).add(parent, input, state);
    }
    
    inline function remove(action:TAction, input:FlxControlInputType)
    {
        return get(action).remove(parent, input);
    }
}

class FlxDigitalSetRaw<TAction:EnumValue> extends FlxActionSet
{
    public final state:FlxInputState;
    public final mappings:Map<TAction, FlxControlDigital> = [];
    
    public var parent:FlxControls<TAction>;
    
    public function new(parent, state)
    {
        this.state = state;
        this.parent = parent;
        
        super('${parent.name}:digital-list-$state');
    }
    
    override function destroy()
    {
        parent = null;
        mappings.clear();
        
        super.destroy();
    }
}

class VirtualPadInputProxy implements IFlxInput
{
    public var target:Null<flixel.ui.FlxButton> = null;
    
    public var justReleased(get, never):Bool;
    public var released(get, never):Bool;
    public var pressed(get, never):Bool;
    public var justPressed(get, never):Bool;
    
    function get_justReleased():Bool return target != null && target.justReleased;
    function get_released    ():Bool return target != null && target.released;
    function get_pressed     ():Bool return target != null && target.pressed;
    function get_justPressed ():Bool return target != null && target.justPressed;
    
    public function new () {}
}

@:allow(flixel.addons.input.FlxDigitalSet)
@:access(flixel.addons.input.FlxControls)
abstract FlxControlDigital(FlxActionDigital) to FlxActionDigital
{
    function new (name, ?callback)
    {
        this = new FlxActionDigital(name, callback);
    }
    
    inline function check() return this.check();
    
    function add<TAction:EnumValue>(parent:FlxControls<TAction>, input:FlxControlInputType, state)
    {
        return switch input
        {
            case Keyboard(id):
                this.addKey(id, state);
            case Gamepad(id):
                this.addGamepad(id, state);
            case VirtualPad(id):
                @:privateAccess
                this.addInput(parent.vPadProxies[id], state);
            case Mouse(Button(id)):
                this.addMouse(id, state);
            case Mouse(found):
                throw 'Internal error - Unexpected Mouse($found)';
        }
    }
    
    function remove<TAction:EnumValue>(parent:FlxControls<TAction>, input:FlxControlInputType):Null<FlxActionInput>
    {
        return switch input
        {
            case Keyboard(id):
                removeKey(id);
            case Gamepad(id):
                removeGamepad(id);
            case VirtualPad(id):
                removeVirtualPad(parent, id);
            case Mouse(Button(id)):
                removeMouse(id);
            case Mouse(_):
                throw 'Mouse not implemented, yet';
        }
    }
    
    function removeKey(key:FlxKey):Null<FlxActionInput>
    {
        for (input in this.inputs)
        {
            if (input.device == KEYBOARD && key == cast input.inputID)
            {
                this.remove(input);
                return input;
            }
        }
        
        return null;
    }
    
    function removeGamepad(id:FlxGamepadInputID):Null<FlxActionInput>
    {
        for (input in this.inputs)
        {
            if (input.device == GAMEPAD && id == cast input.inputID)
            {
                this.remove(input);
                return input;
            }
        }
        
        return null;
    }
    
    function removeMouse(id:FlxMouseButtonID):Null<FlxActionInput>
    {
        for (input in this.inputs)
        {
            if (input.device == MOUSE && id == cast input.inputID)
            {
                this.remove(input);
                return input;
            }
        }
        
        return null;
    }
    
    function removeVirtualPad<TAction:EnumValue>(parent:FlxControls<TAction>, id:FlxVirtualPadInputID):Null<FlxActionInput>
    {
        final proxy = parent.vPadProxies[id];
        for (input in this.inputs)
        {
            @:privateAccess
            if (input is FlxActionInputDigitalIFlxInput && (cast input:FlxActionInputDigitalIFlxInput).input == proxy)
            {
                this.remove(input);
                return input;
            }
        }
        
        return null;
    }
}