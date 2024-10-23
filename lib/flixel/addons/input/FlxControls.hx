package flixel.addons.input;

import flixel.addons.input.FlxAnalogSet;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxDigitalSet;
import flixel.input.FlxInput;
import flixel.input.IFlxInput;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.ui.FlxVirtualPad;
import haxe.ds.ReadOnlyArray;

using Lambda;

typedef ActionMap<TAction:EnumValue> = Map<TAction, Array<FlxControlInputType>>;


@:autoBuild(flixel.addons.system.macros.FlxControlsMacro.buildControls())
abstract class FlxControls<TAction:EnumValue> extends FlxActionManager
{
    static final allStates:ReadOnlyArray<FlxInputState> = [PRESSED, RELEASED, JUST_PRESSED, JUST_RELEASED];
    
    /**
     * The gamepad to use, can either be a specific gamepad ID via `ID(myGamepad.id)`, or
     * a generic term like `FIRST_ACTIVE` or `all`
     */
    public var gamepadID(default, null):FlxGamepadID = FIRST_ACTIVE;
    
    /** The virtual pad to use */
    public var virtualPad(default, null):Null<FlxVirtualPad> = null;
    
    /** The name of these controls, use for logging */
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
    
    /** Used internally for FlxVirtualPads */
    final vPadProxies:Map<FlxVirtualPadInputID, VirtualPadInputProxy> =
        [ UP   => new VirtualPadInputProxy()
        , DOWN => new VirtualPadInputProxy()
        , LEFT => new VirtualPadInputProxy()
        , RIGHT=> new VirtualPadInputProxy()
        , A    => new VirtualPadInputProxy()
        , B    => new VirtualPadInputProxy()
        , C    => new VirtualPadInputProxy()
        , X    => new VirtualPadInputProxy()
        , Y    => new VirtualPadInputProxy()
        ];
    
    /** Used internally to list sets of actions that cannot have conflicting inputs */
    final groups:Map<String, Array<TAction>> = [];
    
    final inputsByAction:Map<TAction, Array<FlxControlInputType>> = [];
    
    public var lastActiveDevice(default, null) = FlxInputDevice.NONE;
    
    final deviceActivity:Map<FlxInputDevice, Int> =
        [ FlxInputDevice.GAMEPAD          => FlxG.game.ticks
        , FlxInputDevice.MOUSE            => FlxG.game.ticks
        , FlxInputDevice.KEYBOARD         => FlxG.game.ticks
        // , FlxInputDevice.IFLXINPUT_OBJECT => FlxG.game.ticks // counts as mouse
        ];
    
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
            
            inputsByAction[action] = [];
            
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
        inputsByAction.clear();
    }
    
    inline public function getAnalog2D(action:TAction):FlxControlAnalog2D
    {
        return analogSet.getAnalog2D(action);
    }
    
    inline public function getAnalog1D(action:TAction):FlxControlAnalog1D
    {
        return analogSet.getAnalog1D(action);
    }
    
    /**
     * The gamepad to use
     * 
     * @param   id  Can either be a specific gamepad ID via `ID(myGamepad.id)`, or
     * a generic term like `FIRST_ACTIVE` or `all`
     */
    public function setGamepadID(id:FlxGamepadID)
    {
        if (gamepadID == id)
            return;
        
        gamepadID = id;
        
        for (set in listsByState)
            set.setGamepadID(id);
    }
    
    abstract function getDefaultMappings():ActionMap<TAction>;
    
    /** The virtual pad to use */
    public function setVirtualPad(pad:FlxVirtualPad)
    {
        virtualPad = pad;
        vPadProxies[FlxVirtualPadInputID.A    ].target = pad.buttonA;
        vPadProxies[FlxVirtualPadInputID.B    ].target = pad.buttonB;
        vPadProxies[FlxVirtualPadInputID.C    ].target = pad.buttonC;
        vPadProxies[FlxVirtualPadInputID.Y    ].target = pad.buttonY;
        vPadProxies[FlxVirtualPadInputID.X    ].target = pad.buttonX;
        vPadProxies[FlxVirtualPadInputID.LEFT ].target = pad.buttonLeft;
        vPadProxies[FlxVirtualPadInputID.UP   ].target = pad.buttonUp;
        vPadProxies[FlxVirtualPadInputID.RIGHT].target = pad.buttonRight;
        vPadProxies[FlxVirtualPadInputID.DOWN ].target = pad.buttonDown;
    }
    
    /**
     * Removes the virtual pad, but does not clear the virtual pad inputs from the action map
     */
    public function removeVirtualPad()
    {
        virtualPad = null;
        for (proxy in vPadProxies)
            proxy.target = null;
    }
    
    // abstract function createVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    
    /**
     * Whether the specified action is in the target state
     * 
     * @param   action  An action the player can perform
     * @param   state   The desired state of digital action
     */
    inline public function checkDigital(action:TAction, state:FlxInputState)
    {
        listsByState[state].check(action);
    }
    
    /**
     * Adds the specified input to the target action
     * 
     * Exmples of acceptable inputs:
     * - `FlxKey.SPACE` or `Keyboard(SPACE)`
     * - `FlxGamepadInputID.A` or `Gamepad(A)`
     * - `FlxMouseButtonID.LEFT` or `Mouse(Button(LEFT))`
     * - `Mouse(Motion())`
     * - `FlxVirtualPadInputID.UP` or `VirtualPad(UP)`
     * 
     * @param   action  The target action
     * @param   input   Any input
     */
    public function add(action:TAction, input:FlxControlInputType):Bool
    {
        // See if this action already has this input
        final existingInput = getExistingInput(action, input);
        if (existingInput != null)
            remove(action, existingInput);
        
        inputsByAction[action].push(input);
        
        if (input.isDigital())
        {
            for (list in listsByState)
                list.add(action, input);
        }
        
        if (input.isAnalog())
            analogSet.add(action, input);
        
        return true;
    }
    
    /**
     * Removes the specified input from the target action
     * 
     * See `add` for a list of valid inputs
     * 
     * @param   action  The target action
     * @param   input   Any input
     */
    public function remove(action:TAction, input:FlxControlInputType):Bool
    {
        // check inputs for valid matches
        final input = getExistingInput(action, input);
        if (input == null)
            return false;
        
        inputsByAction[action].remove(input);
        
        if (input.isDigital())
        {
            for (list in listsByState)
                list.remove(action, input);
        }
        
        if (input.isAnalog())
            analogSet.remove(action, input);
        
        return true;
    }
    
    function getExistingInput(action, input:FlxControlInputType)
    {
        // see if the exact instance is contained
        if (inputsByAction[action].contains(input))
            return input;
        
        // search for matching id and axis
        return inputsByAction[action].find((i)->i.compare(input));
    }
    
    /**
     * Returns a list of all inputs currently added to the specified action
     * 
     * @param   action  The target action
     * @param   device  Used to filter the list results
     */
    public function listInputsFor(action:TAction, device = FlxInputDevice.ALL)
    {
        if (device == ALL)
            return inputsByAction[action].copy();
        
        return inputsByAction[action].filter((input)->input.getDevice() == device);
    }
    
    override function update()
    {
        super.update();
        
        // log the last time each device was used
        for (device in deviceActivity.keys())
        {
            if (isDeviceActive(device))
                deviceActivity[device] = FlxG.game.ticks;
        }
        
        // get which device was last handled
        var latestTicks = deviceActivity[lastActiveDevice];
        for (device=>ticks in deviceActivity)
        {
            if (ticks > latestTicks)
            {
                latestTicks = ticks;
                lastActiveDevice = device;
            }
        }
    }
    
    public function isDeviceActive(device:FlxInputDevice)
    {
        return switch device
        {
            // case FlxInputDevice.IFLXINPUT_OBJECT:
            //     virtualPad != null;
            case FlxInputDevice.KEYBOARD:
                FlxG.keys.pressed.ANY;
            case FlxInputDevice.MOUSE:
                FlxG.mouse.justMoved || FlxG.mouse.pressed || FlxG.mouse.justReleased;
            case FlxInputDevice.GAMEPAD:
                switch gamepadID
                {
                    case ID(id):
                        final gamepad = FlxG.gamepads.getByID(id);
                        gamepad != null && (gamepad.pressed.ANY || gamepad.justReleased.ANY);
                    case FIRST_ACTIVE:
                        final gamepad = FlxG.gamepads.getFirstActiveGamepad();
                        gamepad != null && (gamepad.pressed.ANY || gamepad.justReleased.ANY);
                    case ALL:
                        FlxG.gamepads.anyPressed(ANY);
                    case NONE:
                        false;
                }
            case found:
                throw 'Unhandled device: ${found.getName()}';
        }
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

private class VirtualPadInputProxy implements IFlxInput
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

/**
 * Used to reference specific gamepads by id or with less specific terms like `FIRST_ACTIVE`
 */
abstract FlxGamepadID(FlxGamepadIDRaw) from FlxGamepadIDRaw
{
    @:from
    static public function fromInt(id:Int):FlxGamepadID
    {
        return switch (id)
        {
            case FlxInputDeviceID.FIRST_ACTIVE:
                FlxGamepadIDRaw.FIRST_ACTIVE;
            case FlxInputDeviceID.ALL:
                FlxGamepadIDRaw.ALL;
            case FlxInputDeviceID.NONE:
                FlxGamepadIDRaw.NONE;
            default:
                ID(id);
        }
    }
    
    // @:to
    public function toDeviceID():Int
    {
        return switch this
        {
            case FlxGamepadIDRaw.FIRST_ACTIVE:
                FlxInputDeviceID.FIRST_ACTIVE;
            case FlxGamepadIDRaw.ALL:
                FlxInputDeviceID.ALL;
            case FlxGamepadIDRaw.NONE:
                FlxInputDeviceID.NONE;
            case ID(id):
                id;
        }
    }
}

enum FlxGamepadIDRaw
{
    FIRST_ACTIVE;
    ALL;
    NONE;
    ID(id:Int);
}

