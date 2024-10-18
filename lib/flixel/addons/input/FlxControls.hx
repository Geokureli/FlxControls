package flixel.addons.input;

import flixel.addons.input.FlxAnalogSet;
import flixel.addons.input.FlxDigitalSet;
import flixel.addons.input.FlxControlInputType;
import flixel.input.IFlxInput;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxAction;
// import flixel.input.actions.FlxActionInputAnalog;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseButton;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxAxes;
import flixel.util.typeLimit.OneOfTwo;
import haxe.ds.ReadOnlyArray;

typedef ActionMap<TAction:EnumValue> = Map<TAction, Array<FlxControlInputType>>;

@:autoBuild(flixel.addons.system.macros.FlxControlsMacro.buildControls())
abstract class FlxControls<TAction:EnumValue> extends FlxActionManager
{
    static final allStates:ReadOnlyArray<FlxInputState> = [PRESSED, RELEASED, JUST_PRESSED, JUST_RELEASED];
    
    public var activeGamepad(default, null):Null<FlxGamepad> = null;
    public var activeVPad(default, null):Null<FlxVirtualPad> = null;
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
    
    public function setVirtualPad(pad:FlxVirtualPad)
    {
        activeVPad = pad;
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
    
    public function removeVirtualPad()
    {
        activeVPad = null;
        for (proxy in vPadProxies)
            proxy.target = null;
    }
    
    // abstract function createVirtualPad():ActionMap<TAction, FlxGamepadInputID>;
    
    inline public function checkDigital(action:TAction, state:FlxInputState)
    {
        listsByState[state].check(action);
    }
    
    /**
     * TODO: Explain that it accepts FlxKey and others
     */
    public function add(action:TAction, input:FlxControlInputType)
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
    
    public function remove(action:TAction, input:FlxControlInputType)
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
    
    public function replace(action:TAction, ?oldInput:FlxControlInputType, ?newInput:FlxControlInputType)
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
