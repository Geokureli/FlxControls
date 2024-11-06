package;

import Action;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.input.FlxControls;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	/**
	 * How big the tiles of the tilemap are.
	 */
	static inline var TILE_SIZE:Int = 32;
	
	/**
	 * How many pixels to move each frame.
	 */
	static inline var MOVEMENT_SPEED:Int = 2;
	
	static var controls:Controls;
	
	var _virtualPad:FlxVirtualPad;
	var _analogWidget:AnalogWidget;
	
	var moveX:Float = 0;
	var moveY:Float = 0;
	
	public function new(X:Int, Y:Int)
	{
		// X,Y: Starting coordinates
		super(X, Y);
		
		// Make the player graphic.
		makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.WHITE);
		
		addInputs();
		
		#if debug
		final move = controls.MOVE;
		FlxG.watch.addFunction("move.x|y", ()->'( x: ${move.x} | y: ${move.y} )');
		#end
	}
	
	function addInputs():Void
	{
		controls = new Controls("Main");
		#if (flixel < "5.9.0")
		FlxG.inputs.add(controls);
		#else
		FlxG.inputs.addInput(controls);
		#end
		
		// Add on screen virtual pad to demonstrate UI buttons tied to actions
		_virtualPad = new FlxVirtualPad(FULL, NONE);
		_virtualPad.alpha = 0.5;
		_virtualPad.x += 50;
		_virtualPad.y -= 20;
		FlxG.state.add(_virtualPad);
		controls.setVirtualPad(_virtualPad);

		// Add on screen analog indicator to expose values of analog inputs in real time
		_analogWidget = new AnalogWidget();
		_analogWidget.alpha = 0.5;
		_analogWidget.x -= 10;
		_analogWidget.y -= 2;
		FlxG.state.add(_analogWidget);

		FlxG.mouse.visible = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		velocity.x = 0;
		velocity.y = 0;

		y += moveY * MOVEMENT_SPEED;
		x += moveX * MOVEMENT_SPEED;

		moveX = 0;
		moveY = 0;

		updateDigital();
		updateAnalog();
	}

	function updateDigital():Void
	{
		_virtualPad.buttonUp.color = FlxColor.WHITE;
		_virtualPad.buttonDown.color = FlxColor.WHITE;
		_virtualPad.buttonLeft.color = FlxColor.WHITE;
		_virtualPad.buttonRight.color = FlxColor.WHITE;

		if (controls.pressed.DOWN)
		{
			_virtualPad.buttonDown.color = FlxColor.LIME;
			moveY = 1;
		}
		else if (controls.pressed.UP)
		{
			_virtualPad.buttonUp.color = FlxColor.LIME;
			moveY = -1;
		}

		if (controls.pressed.LEFT)
		{
			_virtualPad.buttonLeft.color = FlxColor.LIME;
			moveX = -1;
		}
		else if (controls.pressed.RIGHT)
		{
			_virtualPad.buttonRight.color = FlxColor.LIME;
			moveX = 1;
		}

		if (moveX != 0 && moveY != 0)
		{
			moveY *= .707;
			moveX *= .707;
		}
	}

	function updateAnalog():Void
	{
		_analogWidget.setValues(controls.MOVE.x, controls.MOVE.y);
		_analogWidget.l = controls.TRIGGER_LEFT.value;
		_analogWidget.r = controls.TRIGGER_RIGHT.value;

		if (Math.abs(moveX) < 0.001)
			moveX = controls.MOVE.x;

		if (Math.abs(moveY) < 0.001)
			moveY = controls.MOVE.y;
	}
}
