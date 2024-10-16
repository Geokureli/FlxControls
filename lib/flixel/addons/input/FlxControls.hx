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
import flixel.input.mouse.FlxMouseButton;
import flixel.util.FlxAxes;
import flixel.util.typeLimit.OneOfTwo;
import haxe.ds.ReadOnlyArray;

enum InputSourceRaw
{
    Keyboard(id:FlxKey);
    Gamepad(id:FlxGamepadInputID); // TODO: add deadzone
    Mouse(id:MouseInputID);
    VirtualPad(id:VirtualPadInputID);
}

enum MouseInputID
{
    /**
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     */
    Position(?axis:FlxAnalogAxis);
    
    /**
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     * @param   scale     Applied to the raw mouse motion. The default `0.1` means moving the
     *                    mouse 10px right will have a value of `1.0`
     * @param   deadzone  A value less than this will be considered `0`, defaults to `0.1`
     * @param   invert    Whether to invert one or both of the axes, defaults to `NONE`
     */
    Motion(?axis:FlxAnalogAxis, ?scale:Float, ?deadzone:Float, ?invert:FlxAxes);
    
    /**
     * @param   id        The id of the mouse button used to drag, defaults to left click
     * @param   axis      The axis to track, defaults to `EITHER`, can also be `X`, `Y` or `BOTH`
     * @param   scale     Applied to the raw mouse motion. The default `0.1` means moving the
     *                    mouse 10px right will have a value of `1.0`
     * @param   deadzone  A value less than this will be considered `0`, defaults to `0.1`
     * @param   invert    Whether to invert one or both of the axes, defaults to `NONE`
     */
    Drag(?id:FlxMouseButtonID, ?axis:FlxAnalogAxis, ?scale:Float, ?deadzone:Float, ?invert:FlxAxes);
    
    /**
     * @param   id  The id of the mouse button used to drag, defaults to left click
     */
    Button(?id:FlxMouseButtonID);
}

enum abstract VirtualPadInputID(String)
{
    var UP    = "up";
    var DOWN  = "down";
    var LEFT  = "left";
    var RIGHT = "right";
    var A     = "a";
    var B     = "b";
    var C     = "c";
    var X     = "x";
    var Y     = "y";
}

abstract InputSource(InputSourceRaw) from InputSourceRaw
{
    // @:from
    // static public function fromIntThrow(id:Int)
    // {
    //     throw 'Unrecognized input: $id';
    // }
    
    // @:from
    // static public function fromStringThrow(id:String)
    // {
    //     throw 'Unrecognized input: $id';
    // }
    
    @:from
    static public function fromKey(id:FlxKey):InputSource
    {
        return Keyboard(id);
    }
    
    @:from
    static public function fromGamepad(id:FlxGamepadInputID):InputSource
    {
        return Gamepad(id);
    }
    
    @:from
    static public function fromVirtualPad(id:VirtualPadInputID):InputSource
    {
        return VirtualPad(id);
    }
    
    @:from
    static public function fromMouseButton(id:FlxMouseButtonID):InputSource
    {
        return Mouse(Button(id));
    }
    
    @:from
    static public function fromMouse(id:MouseInputID):InputSource
    {
        return Mouse(id);
    }
    
    static final gamepadAnalogInputs:ReadOnlyArray<FlxGamepadInputID> = [LEFT_TRIGGER, RIGHT_TRIGGER, LEFT_ANALOG_STICK, RIGHT_ANALOG_STICK];
    public function isDigital()
    {
        return switch this
        {
            case Gamepad(id) if (gamepadAnalogInputs.contains(id)):
                false;
                
            case Mouse(Button(id)):
                true;
                
            case Mouse(_):
                false;
                
            case Keyboard(_) | VirtualPad(_) | Gamepad(_):
                true;
        }
    }
}

typedef ActionMap<TAction> = Map<TAction, Array<InputSource>>;

@:autoBuild(flixel.addons.system.macros.FlxControlsMacro.buildControls())
abstract class FlxControls<TAction:EnumValue> extends FlxActionManager
{
    static final allStates:ReadOnlyArray<FlxInputState> = [PRESSED, RELEASED, JUST_PRESSED, JUST_RELEASED];
    
    public var activeGamepad(default, null):Null<FlxGamepad>;
    public var name(default, null):String;
    
    // These fields are generated via macro
    // public var pressed     (get, never):FlxDigitalSet<TAction>;
    // public var released    (get, never):FlxDigitalSet<TAction>;
    // public var justPressed (get, never):FlxDigitalSet<TAction>;
    // public var justReleased(get, never):FlxDigitalSet<TAction>;
    
    // @:noCompletion inline function get_pressed     () { return listsByState[PRESSED      ]; }
    // @:noCompletion inline function get_released    () { return listsByState[RELEASED     ]; }
    // @:noCompletion inline function get_justPressed () { return listsByState[JUST_PRESSED ]; }
    // @:noCompletion inline function get_justReleased() { return listsByState[JUST_RELEASED]; }
    
    final listsByState = new Map<FlxInputState, FlxDigitalSet<TAction>>();
    
    /** Used internally to get various analog actions */
    final analogSet:FlxAnalogSet<TAction>;
    
    /** Used internally to list sets of actions that cannot have conflicting inputs */
    final groups:Map<String, Array<TAction>> = [];
    
    public function new (name:String)
    {
        this.name = name;
        super();
        
        final mappings = getDefaultMappings();
        
        analogSet = new FlxAnalogSet(this);
        addSet(analogSet);
        
        // Initialize the digital lists
        for (state in allStates)
        {
            listsByState[state] = new FlxDigitalSet(this, state);
            addSet(listsByState[state]);
        }
        
        for (action=>inputs in mappings)
        {
            if (inputs == null)
                throw 'Unexpected null inputs for $action';
            
            for (input in inputs)
                add(action, input);
        }
        
        initGroups();
    }
    
    function initGroups() {}
    
    override function destroy()
    {
        super.destroy();
        
        for (list in listsByState)
            list.destroy();
        
        listsByState.clear();
        analogSet.destroy();
    }
    
    inline public function getAnalog2D(action:TAction):FlxControlAnalog2D
    {
        return analogSet.getAnalog2D(action);
    }
    
    inline public function getAnalog1D(action:TAction):FlxControlAnalog1D
    {
        return analogSet.getAnalog1D(action);
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
    
    abstract function getDefaultMappings():ActionMap<TAction>;
    // abstract function attachVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    // abstract function createVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    
    inline public function checkDigital(action:TAction, state:FlxInputState)
    {
        listsByState[state].check(action);
    }
    
    /**
     * TODO: Explain that it accepts FlxKey and others
     */
    public function add(action:TAction, input:InputSource)
    {
        if (input.isDigital())
        {
            for (list in listsByState)
                list.add(action, input);
        }
        else
        {
            analogSet.add(action, input);
        }
    }
    
    public function remove(action:TAction, input:InputSource)
    {
        if (input.isDigital())
        {
            for (list in listsByState)
                list.remove(action, input);
        }
        else
        {
            analogSet.remove(action, input);
        }
    }
    
    public function replace(action:TAction, ?oldInput:InputSource, ?newInput:InputSource)
    {
        if (oldInput != null)
            remove(action, oldInput);
        
        if (newInput != null)
            add(action, newInput);
    }
    
    /**
     * Prevents sets from being deactivated, not sure why FlxActionManager assumes
     * each input source would have a dedicated set
     */
    override function onChange()
    {
        // Do nothing
    }
}


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
    
    inline function add(action:TAction, input:InputSource)
    {
        return get(action).add(input, state);
    }
    
    inline function remove(action:TAction, input:InputSource)
    {
        return get(action).remove(input);
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


@:allow(flixel.addons.input.FlxDigitalSet)
abstract FlxControlDigital(FlxActionDigital) to FlxActionDigital
{
    function new (name, ?callback)
    {
        this = new FlxActionDigital(name, callback);
    }
    
    inline function check() return this.check();
    
    function add(input:InputSource, state)
    {
        return switch input
        {
            case Keyboard(id):
                this.addKey(id, state);
            case Gamepad(id):
                this.addGamepad(id, state);
            case VirtualPad(_):
                throw 'VirtualPad not implemented, yet';
            case Mouse(Button(id)):
                this.addMouse(id, state);
            case Mouse(found):
                throw 'Internal error - Unexpected Mouse($found)';
        }
    }
    
    function remove(input:InputSource):Null<FlxActionInput>
    {
        return switch input
        {
            case Keyboard(id):
                removeKey(id);
            case Gamepad(id):
                removeGamepad(id);
            case VirtualPad(_):
                throw 'VirtualPad not implemented, yet';
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
}

@:allow(flixel.addons.input.FlxControls)
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
    
    function get(action:TAction)
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
    
    inline function add(action:TAction, input:InputSource)
    {
        return get(action).add(input);
    }
    
    inline function remove(action:TAction, input:InputSource)
    {
        return get(action).remove(input);
    }
}
class FlxAnalogSetRaw<TAction:EnumValue> extends FlxActionSet
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
    
    inline public function addGamepadInput(inputID)
    {
        this.addGamepadInput(inputID, EITHER);
    }
    
    inline public function removeGamepadInput(inputID)
    {
        this.removeGamepadInput(inputID, EITHER);
    }
    
    inline public function addMouseMotion(scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.addMouseMotion(EITHER, scale, deadZone, invert);
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
    
    inline public function addMouseDrag(buttonId, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.addMouseDrag(buttonId, EITHER, scale, deadZone, invert);
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
    
    inline public function addGamepadInput(inputID)
    {
        this.addGamepadInput(inputID, X);
    }
    
    inline public function removeGamepadInput(inputID)
    {
        this.removeGamepadInput(inputID, X);
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

@:allow(flixel.addons.input.FlxAnalogSet)
@:allow(flixel.addons.input.FlxControls)
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
    
    function add(input:InputSource)
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
    
    function remove(input:InputSource)
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
    
    inline function addGamepadInput(inputID:FlxGamepadInputID, axis)
    {
        this.addGamepad(inputID, MOVED, axis);
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
        this.addMouseMotion(MOVED, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
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
    
    inline function addMouseDrag(buttonId, axis, scale = 0.1, deadZone = 0.1, invert = FlxAxes.NONE)
    {
        this.addMouseClickAndDragMotion(buttonId, MOVED, axis, Math.ceil(1.0 / scale), deadZone, invert.y, invert.x);
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