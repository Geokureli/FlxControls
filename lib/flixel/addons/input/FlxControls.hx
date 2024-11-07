package flixel.addons.input;

import flixel.addons.input.FlxAnalogSet;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxDigitalSet;
import flixel.input.FlxInput;
import flixel.input.IFlxInput;
import flixel.input.IFlxInputManager;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionManager;
import flixel.input.gamepad.FlxGamepad;
import flixel.ui.FlxVirtualPad;
import haxe.ds.ReadOnlyArray;

using Lambda;
using flixel.addons.input.FlxControls.DigitalEventTools;

typedef ActionMap<TAction:EnumValue> = Map<TAction, Array<FlxControlInputType>>;
typedef VPadMap = Map<FlxVirtualPadInputID, VirtualPadInputProxy>;

private class ActionManager extends FlxActionManager
{
    /**
     * Prevents sets from being deactivated, not sure why FlxActionManager assumes
     * each input source would have a dedicated set
     */
    override function onChange()
    {
        // Do nothing
    }
}


@:autoBuild(flixel.addons.system.macros.FlxControlsMacro.buildControls())
abstract class FlxControls<TAction:EnumValue> implements IFlxInputManager
{
    /**
     * The gamepad to use, can either be a specific gamepad ID via `ID(myGamepad.id)`, or
     * a generic term like `FIRST_ACTIVE` or `all`
     */
    public var gamepadID(default, null):FlxDeviceID = ALL;
    
    /** The virtual pad to use */
    public var virtualPad(default, null):Null<FlxVirtualPad> = null;
    
    /** The name of these controls, use for logging */
    public var name(default, null):String;
    
    /**
     * The action manager used to track all the inputs
     */
    final manager:ActionManager;
    
    // These fields are generated via macro
    // public var pressed     (get, never):FlxDigitalSet<TAction>;
    // public var released    (get, never):FlxDigitalSet<TAction>;
    // public var justPressed (get, never):FlxDigitalSet<TAction>;
    // public var justReleased(get, never):FlxDigitalSet<TAction>;
    
    // @:noCompletion inline function get_pressed     () { return digitalSets[PRESSED      ]; }
    // @:noCompletion inline function get_released    () { return digitalSets[RELEASED     ]; }
    // @:noCompletion inline function get_justPressed () { return digitalSets[JUST_PRESSED ]; }
    // @:noCompletion inline function get_justReleased() { return digitalSets[JUST_RELEASED]; }
    
    final digitalSets = new Map<DigitalEvent, FlxDigitalSet<TAction>>();
    final analogSets = new Map<TAction, FlxAnalogSet<TAction>>();
    
    /** Used internally for FlxVirtualPads */
    final vPadProxies:VPadMap =
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
    
    public function new (name = "Main")
    {
        this.name = name;
        manager = new ActionManager();
        
        // Initialize the digital lists
        for (event in DigitalEvent.createAll())
            digitalSets[event] = new FlxDigitalSet(this, event);
        
        addMappings(getDefaultMappings());
        
        initGroups();
    }
    
    function initGroups() {}
    
    public function destroy()
    {
        manager.destroy();
        
        for (list in digitalSets)
            list.destroy();
        
        for (list in analogSets)
            list.destroy();
        
        digitalSets.clear();
        analogSets.clear();
        inputsByAction.clear();
    }
    
    inline public function getAnalog2D(action:TAction):FlxAnalogSet2D<TAction>
    {
        return cast analogSets.get(action);
    }
    
    inline public function getAnalog1D(action:TAction):FlxAnalogSet1D<TAction>
    {
        return cast analogSets.get(action);
    }
    
    // inline public function getAnalog1D(action:TAction):FlxControlAnalog1D
    // {
    //     return analogSet.getAnalog1D(action);
    // }
    
    /**
     * The gamepad to use
     * 
     * @param   id  Can either be a specific gamepad ID via `ID(myGamepad.id)`, or
     * a generic term like `FIRST_ACTIVE` or `all`
     */
    public function setGamepadID(id:FlxDeviceID)
    {
        if (gamepadID == id)
            return;
        
        gamepadID = id;
        
        for (set in digitalSets)
            set.setGamepadID(id);
        
        for (set in analogSets)
            set.setGamepadID(id);
    }
    
    abstract function getDefaultMappings():ActionMap<TAction>;
    
    /**
     * Removes all mapped inputs
     */
    public function clearMappings()
    {
        // Clear each digital set, but don't destroy
        for (set in digitalSets)
            set.clear();
        
        // Destroy and remove all analog sets
        for (list in analogSets)
            list.destroy();
        
        analogSets.clear();
        inputsByAction.clear();
    }
    
    /**
     * Removes all mapped inputs and adds all the new ones passed in
     */
    public function resetMappings(mappings:ActionMap<TAction>)
    {
        clearMappings();
        addMappings(mappings);
    }
    
    function addMappings(mappings:ActionMap<TAction>)
    {
        for (action=>inputs in mappings)
        {
            if (inputs == null)
                throw 'Unexpected null inputs for $action';
            
            inputsByAction[action] = [];
            
            for (input in inputs)
                add(action, input);
        }
    }
    
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
     * @param   event   The event to check for. Possible values:
     * `PRESSED`, `JUST_PRESSED`, `RELEASED`, `JUST_RELEASED` and `REPEAT`
     */
    inline public function checkDigital(action:TAction, event:DigitalEvent)
    {
        digitalSets[event].check(action);
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
            for (list in digitalSets)
                list.add(action, input);
        }
        
        if (input.isAnalog())
            getAnalogSet(action).add(input);
        
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
            for (list in digitalSets)
                list.remove(action, input);
        }
        
        if (input.isAnalog())
            getAnalogSet(action).remove(input);
        
        return true;
    }
    
    function getAnalogSet(action:TAction)
    {
        if (analogSets.exists(action) == false)
            analogSets[action] = new FlxAnalogSet(this, action);
        
        return analogSets[action];
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
    
    #if (flixel >= "5.9.0")
    /**
     * Returns a device specific id for every input that can be attached to an action. For gamepads it will use
     * identifiers such as `WII_REMOTE(A)` or `PS4(SQUARE)`. For keyboard, the button label is returned.
     * for "Multi button" inputs (like analog WASD), an array is returned.
     * 
     * @param   action  The target action
     * @param   device  Used to filter the list results
     */
    public function listMappedInputsFor(action:TAction, device = FlxInputDevice.ALL)
    {
        final gamepad = getActiveGamepad();
        return listInputsFor(action, device).map((input)->input.getMappedInput(gamepad));
    }
    #end
    
    /**
     * Returns a list of all inputs currently added to the specified action
     * 
     * @param   action  The target action
     * @param   device  Used to filter the list results
     */
    public function listInputLabelsFor(action:TAction, device = FlxInputDevice.ALL)
    {
        final gamepad = getActiveGamepad();
        return listInputsFor(action, device).map((input)->input.getLabel(gamepad));
    }
    
    
    public function reset()
    {
        manager.reset();
        // No idea what should happen here, nothing happens in FlxActionManager
    }
    function onFocus() { @:privateAccess manager.onFocus(); }
    function onFocusLost() { @:privateAccess manager.onFocusLost(); }
    
    function update()
    {
        @:privateAccess manager.update();
        
        for (set in analogSets)
            set.update();
        
        for (set in digitalSets)
            set.update();
        
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
                #if (flixel < "5.9.0")
                FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0
                #else
                FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0
                #end
                || FlxG.mouse.pressed || FlxG.mouse.justReleased
                #if FLX_MOUSE_ADVANCED
                || FlxG.mouse.pressedMiddle || FlxG.mouse.justReleasedMiddle
                || FlxG.mouse.pressedRight || FlxG.mouse.justReleasedRight
                #end
                || FlxG.mouse.wheel != 0
                ;
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
    
    public function getActiveGamepad():Null<FlxGamepad>
    {
        return switch gamepadID
        {
            case ID(id):
                FlxG.gamepads.getByID(id);
            case FIRST_ACTIVE | ALL:
                FlxG.gamepads.getFirstActiveGamepad();
            case NONE:
                null;
        }
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
abstract FlxDeviceID(FlxDeviceIDRaw) from FlxDeviceIDRaw
{
    @:from
    static public function fromInt(id:Int):FlxDeviceID
    {
        return switch (id)
        {
            case FlxInputDeviceID.FIRST_ACTIVE:
                FlxDeviceIDRaw.FIRST_ACTIVE;
            case FlxInputDeviceID.ALL:
                FlxDeviceIDRaw.ALL;
            case FlxInputDeviceID.NONE:
                FlxDeviceIDRaw.NONE;
            default:
                ID(id);
        }
    }
    
    // @:to
    public function toDeviceID():Int
    {
        return switch this
        {
            case FlxDeviceIDRaw.FIRST_ACTIVE:
                FlxInputDeviceID.FIRST_ACTIVE;
            case FlxDeviceIDRaw.ALL:
                FlxInputDeviceID.ALL;
            case FlxDeviceIDRaw.NONE:
                FlxInputDeviceID.NONE;
            case ID(id):
                id;
        }
    }
}

enum FlxDeviceIDRaw
{
    FIRST_ACTIVE;
    ALL;
    NONE;
    ID(id:Int);
}

@:using(flixel.addons.input.FlxControls.DigitalEventTools)
@:noCompletion
enum DigitalEvent
{
    PRESSED;
    JUST_PRESSED;
    RELEASED;
    JUST_RELEASED;
    REPEAT;
}

private class DigitalEventTools
{
    static public function toEvent(state:FlxInputState):DigitalEvent
    {
        return switch state
        {
            case FlxInputState.PRESSED      : DigitalEvent.PRESSED;
            case FlxInputState.JUST_PRESSED : DigitalEvent.JUST_PRESSED;
            case FlxInputState.RELEASED     : DigitalEvent.RELEASED;
            case FlxInputState.JUST_RELEASED: DigitalEvent.JUST_RELEASED;
        }
    }
    
    static public function toState(event:DigitalEvent):FlxInputState
    {
        return switch event
        {
            case PRESSED | REPEAT: FlxInputState.PRESSED;
            case JUST_PRESSED    : FlxInputState.JUST_PRESSED;
            case RELEASED        : FlxInputState.RELEASED;
            case JUST_RELEASED   : FlxInputState.JUST_RELEASED;
        }
    }
}