package input;

import flixel.FlxG;
import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputID as VPad;
import flixel.input.gamepad.FlxGamepadInputID as GPad;
import flixel.input.keyboard.FlxKey as Key;
import flixel.ui.FlxVirtualPad;

enum Input
{
	// Movement
	LEFT; RIGHT; UP; DOWN;
	// UI
	STYLE_NEXT; STYLE_PREV;
	ZOOM_IN   ; ZOOM_OUT  ;
	LEAD_UP   ; LEAD_DOWN ;
	LERP_UP   ; LERP_DOWN ;
	/** Triggers screen shake */
	SHAKE;
}

class PlayerControls extends FlxControls<Input>
{
	
	function getDefaultMappings():ActionMap<Input>
	{
		return
			[ Input.UP         => [Key.UP   , Key.W, DPAD_UP   , LEFT_STICK_DIGITAL_UP   , VPad.UP   ]
			, Input.DOWN       => [Key.DOWN , Key.S, DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN , VPad.DOWN ]
			, Input.LEFT       => [Key.LEFT , Key.A, DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT , VPad.LEFT ]
			, Input.RIGHT      => [Key.RIGHT, Key.D, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, VPad.RIGHT]
			, Input.STYLE_NEXT => [Key.Y           , GPad.RIGHT_SHOULDER                             ]
			, Input.STYLE_PREV => [Key.H           , GPad.LEFT_SHOULDER                              ]
			, Input.LERP_UP    => [Key.U           , GPad.RIGHT_TRIGGER                              ]
			, Input.LERP_DOWN  => [Key.J           , GPad.LEFT_TRIGGER                               ]
			, Input.LEAD_UP    => [Key.I           , GPad.X                                          ]
			, Input.LEAD_DOWN  => [Key.K           , GPad.A                                          ]
			, Input.ZOOM_IN    => [Key.O           , GPad.Y                                          ]
			, Input.ZOOM_OUT   => [Key.L           , GPad.B                                          ]
			, Input.SHAKE      => [Key.M           , GPad.RIGHT_STICK_CLICK                                      ]
			];
	}
}

/**
 * Simplified virtual pad that takes an Input and returns whether the corresponding button is pressed
 */
abstract VirtualPad(FlxVirtualPad) from FlxVirtualPad to FlxVirtualPad
{
	inline public function new()
	{
		this = new FlxVirtualPad(FULL, NONE);
	}
}