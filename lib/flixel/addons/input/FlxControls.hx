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
    /** Looks up the group of an action */
    final groupsLookup:Map<TAction, Array<String>> = [];
    
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
        // Create reverse lookups  for each group
        for (name=>actions in groups)
        {
            for (action in actions)
                groupsOfRaw(action).push(name);
        }
        
        #if (FlxControls.checkConflictingDefaults)
        throwAllGroupConflicts();
        #end
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
    
    /**
     * Checks for all group conflicts and throws an informative error, if any are found
     */
    public function throwAllGroupConflicts()
    {
        switch (checkAllGroupConflicts())
        {
            case None:
            case Found(list):
                final strList = list.map((conflict)->conflict.toString());
                strList.unshift("Found conflicting inputs in the default layout:");
                throw strList.join("\n\t - ");
        }
    }
    
    inline public function getAnalog2D(action:TAction):FlxAnalogSet2D<TAction>
    {
        return cast analogSets.get(action);
    }
    
    inline public function getAnalog1D(action:TAction):FlxAnalogSet1D<TAction>
    {
        return cast analogSets.get(action);
    }
    
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
    
    /**
     * Removes all groups
     */
    public function clearGroups()
    {
        groups.clear();
        groupsLookup.clear();
    }
    
    /**
     * Adds the group, removing any previous group with that name. Groups are a way to prevent
     * opposing actions from having the same input. For instance you might want to put
     * `ACCEPT` and `CANCEL` in the same group, or `UP` and `DOWN`
     * 
     * @param name     The name of the group
     * @param actions  The actions in this group
     */
    public function addGroup(name:String, actions:Array<TAction>)
    {
        if (groups.exists(name))
            removeGroup(name);
        
        // Add the group
        groups[name] = actions;
        
        // Add the reverse lookup
        for (action in actions)
            groupsOfRaw(action).push(name);
    }
    
    /**
     * Removes the group, by name. Not sure why anyone would need this
     */
    public function removeGroup(name:String)
    {
        if (groups.exists(name))
        {
            for (action in groups[name])
                groupsOfRaw(action).remove(name);
        }
        groups.remove(name);
    }
    
    /**
     * Creates a list of all groups containing the target action
     */
    public function groupsOf(action:TAction):Array<String>
    {
        return groupsOfRaw(action).copy();
    }
    
    /**
     * Used internally to get or modify the stored groups of an action. Same as `groupsOf` but
     * doesn't return a copy
     */
    function groupsOfRaw(action:TAction):Array<String>
    {
        if (groupsLookup.exists(action) == false)
            groupsLookup[action] = [];
        
        return groupsLookup[action];
    }
    
    inline function groupInstancesOf(action:TAction):Array<Array<TAction>>
    {
        return groupsOfRaw(action).map((g)->groups[g]);
    }
    
    /**
     * Creates a list of every conflict, in every group. A "conflict" is when two actions
     * in the same group are using the same input
     */
    public function checkAllGroupConflicts()
    {
        final list = new Array<GroupConflict<TAction>>();
        for (name=>group in groups)
            GroupTools.addAllConflicts(this, name, group, list);
        
        return list.length > 0 ? Found(list) : None;
    }
    
    /**
     * Creates a list of every conflict, in a specific group. A "conflict" is when two actions
     * in the group are using the same input
     */
    public function checkGroupConflicts(group:String)
    {
        final list = new Array<GroupConflict<TAction>>();
        GroupTools.addAllConflicts(this, group, groups[group], list);
        return list.length > 0 ? Found(list) : None;
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
     * Whether adding an input to an action will cause conflicts with other actions in the same group
     * 
     * **Note:** To get a list of those conflicts, use `listConflictingActions`
     * 
     * @param   action  The would be action to add the input
     * @param   input   The input to be added
     */
    public function canAdd(action:TAction, input:FlxControlInputType):Bool
    {
        return canAddHelper(action, input, true).match(None);
    }
    
    /**
     * Determines whether adding an input to an action will cause conflicts with
     * other actions in the same group, and returns those conflicting actions.
     * 
     * @param   action  The would be action to add the input
     * @param   input   The input to be added
     * @return  A list of conflicting actions
     */
    public function listConflictingActions(action:TAction, input:FlxControlInputType):GroupConflictsResults<TAction>
    {
        return canAddHelper(action, input);
    }
    
    function canAddHelper(action:TAction, input:FlxControlInputType, firstOnly = false):GroupConflictsResults<TAction>
    {
        final conflicts = new Array<GroupConflict<TAction>>();
        for (groupName in groupsOfRaw(action))
        {
            final actionConflicts = GroupTools.getConflictingActions(this, groups[groupName], input);
            for (action1 in actionConflicts)
            {
                if (action1 != action)
                {
                    conflicts.push(new GroupConflict(groupName, action1, action, input));
                    if (firstOnly)
                        return GroupTools.resultsFromArray(conflicts);
                }
            }
        }
        
        return GroupTools.resultsFromArray(conflicts);
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
    public function add(action:TAction, input:FlxControlInputType)
    {
        // See if this action already has this input
        final existingInput = getExistingInput(action, input);
        if (existingInput != null)
            remove(action, existingInput);
        
        getInputsOf(action).push(input);
        
        if (input.isDigital())
        {
            for (list in digitalSets)
                list.add(action, input);
        }
        
        if (input.isAnalog())
            getAnalogSet(action).add(input);
    }
    
    /**
     * Same as `add` but checks if adding the input will cause a conflict in a group
     * 
     * @param   action  The target action
     * @param   input   Any input
     * @return Any conflicts that would have arisen from the addition of this input
     */
    public function addIfValid(action:TAction, input:FlxControlInputType):GroupConflictsResults<TAction>
    {
        final conflicts = canAddHelper(action, input);
        if (conflicts.match(None))
            add(action, input);
        
        return conflicts;
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
        
        getInputsOf(action).remove(input);
        
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
        final inputs = getInputsOf(action);
        // see if the exact instance is contained
        if (inputs.contains(input))
            return input;
        
        // search for matching id and axis
        return inputs.find(input.compare);
    }
    
    function getConflictingInput(action, input:FlxControlInputType)
    {
        final inputs = getInputsOf(action);
        // see if the exact instance is contained
        if (inputs.contains(input))
            return input;
        
        // search for matching id and axis
        return inputs.find(input.conflicts);
    }
    
    /**
     * Returns a list of all inputs currently added to the specified action
     * 
     * @param   action  The target action
     * @param   device  Used to filter the list results
     */
    public function listInputsFor(action:TAction, device = FlxInputDevice.ALL)
    {
        final inputs = getInputsOf(action);
        if (device == ALL)
            return inputs.copy();
        
        return inputs.filter((input)->input.getDevice() == device);
    }
    
    function getInputsOf(action:TAction)
    {
        if (inputsByAction.exists(action) == false)
            inputsByAction[action] = [];
        
        return inputsByAction[action];
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

private class GroupTools
{
    static public function addAllConflicts<TAction:EnumValue>
        (controls:FlxControls<TAction>, groupName:String, group:Array<TAction>, conflicts:Array<GroupConflict<TAction>>)
    {
        final inputs = group.map((action)->controls.listInputsFor(action));
        function addConflict(i, j, input)
        {
            conflicts.push(new GroupConflict(groupName, group[i], group[j], input));
        }
        // Iterate through and only compare with previous indices
        var i = group.length;
        while (i-- > 0)
        {
            var j = i;
            while (j-- > 0)
                forEachConflict(inputs[i], inputs[j], (input)->addConflict(i, j, input));
        }
    }
    
    static function forEachConflict
    (
        listA:Array<FlxControlInputType>,
        listB:Array<FlxControlInputType>,
        func:(FlxControlInputType)->Void
    )
    {
        for (inputA in listA)
        {
            if (listB.exists(inputA.conflicts))
                func(inputA);
        }
    }
    
    /**
     * Checks each group for actions with inputs matching the target input. Should be used before an input is added
     * 
     * @param   controls  The controls instance
     * @param   group     A list of actions that should not have conflicts
     * @param   input     The input to look for
     */
    static public function getConflictingActions<TAction:EnumValue>
        (controls:FlxControls<TAction>, group:Array<TAction>, input:FlxControlInputType)
    {
        final list = new Array<TAction>();
        for (action in group)
        {
            final inputs = controls.listInputsFor(action);
            if (inputs.exists(input.conflicts))
                list.push(action);
        }
        return list;
    }
    
    static public function resultsFromArray<TAction:EnumValue>(list:Array<GroupConflict<TAction>>):GroupConflictsResults<TAction>
    {
        return list.length == 0 ? None : Found(list);
    }
    
    static public function resultsFromActionArray<TAction:EnumValue>
        (list:Array<TAction>, group:String, action2:TAction, input:FlxControlInputType):GroupConflictsResults<TAction>
    {
        return resultsFromArray(list.map((action1)->new GroupConflict(group, action1, action2, input)));
    }
}

/**
 * The results of a group conflict check.
 * 
 * A group conflict is when two actions belonging to the same group both use the same input.
 * Conflicts in actions with opposing purposes may cause odd behavior, or restict the actions
 * of the player
 */
enum GroupConflictsResults<TAction:EnumValue>
{
    /** No conflicts were found */
    None;
    
    /** One or more conflicts were found */
    Found(list:Array<GroupConflict<TAction>>);
}

/**
 * A group conflict is when two actions belonging to the same group both use the same input.
 * Conflicts in actions with opposing purposes may cause odd behavior, or restict the actions
 * of the player
 */
@:structInit
class GroupConflict<TAction:EnumValue>
{
    public final group:String;
    public final action1:TAction;
    public final action2:TAction;
    public final input:FlxControlInputType;
    
    public function new (group, action1, action2, input)
    {
        this.group = group;
        this.action1 = action1;
        this.action2 = action2;
        this.input = input;
    }
    
    public function toString()
    {
        return '$input in group "$group" on actions $action1 and $action2';
    }
}