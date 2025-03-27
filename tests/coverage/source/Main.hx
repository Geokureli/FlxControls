package ;

import flixel.ui.FlxButton;
import flixel.addons.input.FlxControls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.ui.FlxVirtualPad;
import flixel.ui.FlxVirtualStick;
import input.Controls;

class Main extends openfl.display.Sprite
{
    public function new()
    {
        super();
        
        addChild(new flixel.FlxGame(0, 0, BootState));
    }
}

class BootState extends flixel.FlxState
{
    var controls:Controls;
    var sprite:FlxSprite;
    var inputPad:FlxVirtualPad;
    var displayPad:FlxVirtualPad;
    var repeatDPad:VirtualRepeatDPadButtons;
    var repeatActions:FlxVirtualActionButtons;
    
    override function create()
    {
        controls = new Controls("test");
        #if (flixel < version("5.9.0"))
        FlxG.inputs.add(controls);
        #else
        FlxG.inputs.addInput(controls);
        #end
        
        controls.setGamepadID(FlxDeviceID.FIRST_ACTIVE);
        
        add(inputPad = new FlxVirtualPad(ANALOG, A_B_X_Y));
        controls.setVirtualPad(inputPad);
        
        add(displayPad = new FlxVirtualPad(ANALOG, A_B_X_Y));
        displayPad.stick.x += 50;
        displayPad.y = 50;
        displayPad.active = false;
        add(repeatDPad = new VirtualRepeatDPadButtons(displayPad.stick));
        repeatDPad.active = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        final moveRepeat = controls.MOVE.waitAndRepeat();
        final pressed = controls.pressed;
        final repeat = controls.waitAndRepeat();
        
        @:privateAccess
        final value:FlxPoint = cast displayPad.stick.value;
        value.x = controls.MOVE.x;
        value.y = controls.MOVE.y;
        @:privateAccess
        final thumb = displayPad.stick.thumb;
        @:privateAccess
        final base = displayPad.stick.base;
		thumb.x = base.x + base.radius - thumb.radius + value.x * (base.radius - thumb.radius);
		thumb.y = base.y + base.radius - thumb.radius + value.y * (base.radius - thumb.radius);
        
        repeatDPad.setButtonState(DOWN , controls.MOVE.pressed.down , moveRepeat.down );
        repeatDPad.setButtonState(UP   , controls.MOVE.pressed.up   , moveRepeat.up   );
        repeatDPad.setButtonState(LEFT , controls.MOVE.pressed.left , moveRepeat.left );
        repeatDPad.setButtonState(RIGHT, controls.MOVE.pressed.right, moveRepeat.right);
        
        setButtonState(displayPad.actions, A, pressed.GREEN , repeat.GREEN );
        setButtonState(displayPad.actions, B, pressed.RED   , repeat.RED   );
        setButtonState(displayPad.actions, X, pressed.BLUE  , repeat.BLUE  );
        setButtonState(displayPad.actions, Y, pressed.YELLOW, repeat.YELLOW);
    }
    
    inline public function getButton(buttons:FlxVirtualPadButtons, id):Null<VirtualPadButton>
    {
        return buttons.getButton(id);
    }
    
    public function setButtonState(pad:VirtualRepeatButtons, id, pressed, repeat)
    {
        getButton(pad, id).setState(pressed, repeat);
    }
}

@:forward
@:forward.new
@:forward.variance
@:access(flixel.ui.FlxButton)
@:access(flixel.ui.FlxVirtualPad.FlxVirtualPadButton)
abstract VirtualPadButton(FlxVirtualPadButton) from FlxVirtualPadButton
{
    inline public function setState(pressed:Bool, repeat:Bool)
    {
        // Update the button, but only if at least either mouse or touches are enabled
        if (pressed)
        {
            this.onOverHandler();
            this.onDownHandler();
        }
        else
        {
            this.onUpHandler();
            this.onOutHandler();
        }
        
        // Trigger the animation only if the button's input status changes.
        if (this.lastStatus != this.status)
        {
            this.updateStatusAnimation();
            this.lastStatus = this.status;
        }
        
        if (repeat)
            this.setColorTransform(1, 1, 1, 1, 0x40, 0x40, 0x40);
        else
            this.setColorTransform();
        
        this.input.update();
    }
}

@:forward
abstract VirtualRepeatButtons(FlxVirtualPadButtons) to FlxVirtualPadButtons from FlxVirtualPadButtons
{
    public function setButtonState(id, pressed:Bool, repeat:Bool)
    {
        getButton(id).setState(pressed, repeat);
    }
    
    public function getButton(id):VirtualPadButton
    {
        return this.getButton(id);
    }
}

@:forward
abstract VirtualRepeatDPadButtons(VirtualRepeatButtons) to VirtualRepeatButtons from FlxVirtualPadButtons to FlxVirtualPadButtons
{
    var up(get, never):VirtualPadButton;
    inline function get_up() return this.getButton(UP);
    var down(get, never):VirtualPadButton;
    inline function get_down() return this.getButton(DOWN);
    var left(get, never):VirtualPadButton;
    inline function get_left() return this.getButton(LEFT);
    var right(get, never):VirtualPadButton;
    inline function get_right() return this.getButton(RIGHT);
    
    public function new (stick:FlxVirtualStick)
    {
        this = new FlxVirtualDPadButtons(stick.x - 45, stick.y - 45, FULL);
        up.x = stick.x + (stick.width - up.width) / 2;
        down.x = stick.x + (stick.width - down.width) / 2;
        down.y = stick.y + stick.height;
        left.y = stick.y + (stick.height - left.height) / 2;
        right.x = stick.x + stick.width;
        right.y = stick.y + (stick.height - right.height) / 2;
    }
}