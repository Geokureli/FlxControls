package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.actions.FlxActionInput;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import input.PlayerControls;

inline var WIDTH = 200;
inline var HEIGHT = 180;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class HUD extends FlxGroup
{
	var txtStyle:Text;
	var txtLerp:Text;
	var txtLead:Text;
	var txtZoom:Text;
	
	var infoMove:Text;
	var infoStyle:Text;
	var infoLerp:Text;
	var infoLead:Text;
	var infoZoom:Text;
	
	var lastActiveDevice = FlxInputDevice.KEYBOARD;

	public function new()
	{
		super();
		
		var left = 6;
		var startY = 10;
		
		add(infoMove = new Text(left, startY, "[W,A,S,D] or arrows to control the orb."));

		add(infoStyle = new Text(left, startY + 20, "[H] or [Y] to change follow style."));
		add(txtStyle = new GreenText(left, startY + 33, "LOCKON"));

		add(infoLerp = new Text(left, startY + 55, "[U] or [J] to change lerp."));
		add(txtLerp = new GreenText(left, startY + 68, "Camera lerp: 1"));

		add(infoLead = new Text(left, startY + 95, "[I] or [K] to change lead."));
		add(txtLead = new GreenText(left, startY + 108, "Camera lead: 0"));

		add(infoZoom = new Text(left, startY + 135, "[O] or [L] to change zoom."));
		add(txtZoom = new GreenText(left, startY + 148, "Camera zoom: 1"));
		
		// create new camera in the top-right corner that only draws this
		camera = new FlxCamera(440, 0, WIDTH, HEIGHT, 1.0);
		camera.alpha = .5;
		camera.bgColor = 0x80000000;
		FlxG.cameras.add(camera, false);
	}
	
	public function updateInfo(controls:PlayerControls)
	{
		final device:FlxInputDevice = controls.lastActiveDevice == GAMEPAD ? GAMEPAD : KEYBOARD;
		
		if (lastActiveDevice == device)
			return;
		
		if (device == GAMEPAD)
			infoMove.text = "D-pad or left-stick to control the orb.";
		else
			infoMove.text = "[W,A,S,D] or arrows to control the orb.";
		
		function label(input:Input)
		{
			final label = controls.listInputLabelsFor(input, device)[0];
			if (label == null)
				throw 'Missing label for input $input';
			return '${label.split(",").map((s)->'[${s.toUpperCase()}]').join(" or ")}';
		}
		
		infoStyle.text = '${label(STYLE)} to change follow style.';
		infoLerp.text = '${label(LERP)} to change lerp.';
		infoLead.text = '${label(LEAD)} to change lead.';
		infoZoom.text = '${label(ZOOM)} to change zoom.';
		
		lastActiveDevice = device;
	}

	public function updateStyle(style:FlxCameraFollowStyle)
	{
		txtStyle.text = Std.string(style);
	}

	public function updateCamLerp(lerp:Float)
	{
		txtLerp.text = "Camera lerp: " + lerp;
	}

	public function updateCamLead(lead:Float)
	{
		txtLead.text = "Camera lead: " + lead;
	}

	public function updateZoom(zoom:Float)
	{
		txtZoom.text = "Camera Zoom: " + Math.floor(zoom * 10) / 10;
	}
}

/**
 * A simplified, specialized FlxText instance, mainly used to omit the fieldWidth arg
 */
@:forward
abstract Text(FlxText) from FlxText to FlxText
{
	inline public function new (x = 0.0, y = 0.0, ?text:String, size = 8)
	{
		this = new FlxText(x, y, WIDTH, text, size);
		#if debug
		this.ignoreDrawDebug = true;
		#end
	}
}

/**
 * An even more specialized version of Text used to highlight the changing camera values
 */
@:forward
abstract GreenText(Text) from Text to Text
{
	inline public function new (x = 0.0, y = 0.0, ?text:String)
	{
		this = new Text(x, y, text);
		this.setFormat(null, 11, 0x55FF55);
	}
}
