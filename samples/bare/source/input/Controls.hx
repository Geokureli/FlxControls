package input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Action
{
    /** Moves the player up, also used to navigate menus */
    @:gamepad(LEFT_STICK_DIGITAL_UP, DPAD_UP)
    @:keys(UP, W)
    @:vpad(UP)
    UP;
    
    /** Moves the player down, also used to navigate menus */
    @:gamepad(LEFT_STICK_DIGITAL_DOWN, DPAD_DOWN)
    @:keys(DOWN , S)
    @:vpad(DOWN)
    DOWN;
    
    /** Moves the player left, also used to navigate menus */
    @:gamepad(LEFT_STICK_DIGITAL_LEFT, DPAD_LEFT)
    @:keys(LEFT , A)
    @:vpad(LEFT)
    LEFT;
    
    /** Moves the player right, also used to navigate menus */
    @:gamepad(LEFT_STICK_DIGITAL_RIGHT, DPAD_RIGHT)
    @:keys(RIGHT, D)
    @:vpad(RIGHT)
    RIGHT;
    
    /** Makes the player jump */
    @:gamepad(A)
    @:keys(L, X)
    @:vpad(A)
    JUMP;
    
    /** Makes the player shoot */
    @:gamepad(Y)
    @:keys(K, Z)
    @:vpad(Y)
    SHOOT;
    
    /** Used to select options in the menu */
    @:gamepad(A)
    @:keys(K, Z)
    @:vpad(A)
    ACCEPT;
    
    /** Used to cancel or exit a menu */
    @:gamepad(B)
    @:keys(L, X)
    @:vpad(B)
    BACK;
    
    /** Pauses the game */
    @:gamepad(START)
    @:keys(ENTER)
    @:vpad(X)
    PAUSE;
    
    /** A test action */
    @:keys(SPACE)
    KEY;
    
    @:analog(x, y)
    CAM;
}

class Controls extends FlxControls<Action>
{
    function getDefaultMappings():ActionMap<Action>
    {
        return
            [ Action.UP    => [FlxKey.UP   , FlxKey.W, FlxGamepadInputID.DPAD_UP   , FlxGamepadInputID.LEFT_STICK_DIGITAL_UP   , FlxVirtualPadInputID.UP    ]
            , Action.DOWN  => [FlxKey.DOWN , FlxKey.S, FlxGamepadInputID.DPAD_DOWN , FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN , FlxVirtualPadInputID.DOWN  ]
            , Action.LEFT  => [FlxKey.LEFT , FlxKey.A, FlxGamepadInputID.DPAD_LEFT , FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT , FlxVirtualPadInputID.LEFT  ]
            , Action.RIGHT => [FlxKey.RIGHT, FlxKey.D, FlxGamepadInputID.DPAD_RIGHT, FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT, FlxVirtualPadInputID.RIGHT ]
            , Action.JUMP  => [FlxKey.L    , FlxKey.X, FlxGamepadInputID.A         , FlxVirtualPadInputID.B ]
            , Action.SHOOT => [FlxKey.K    , FlxKey.Z, FlxGamepadInputID.X         , FlxVirtualPadInputID.Y ]
            , Action.ACCEPT=> [FlxKey.K    , FlxKey.Z, FlxGamepadInputID.A         , FlxVirtualPadInputID.A ]
            , Action.BACK  => [FlxKey.L    , FlxKey.X, FlxGamepadInputID.B         , FlxVirtualPadInputID.B ]
            , Action.PAUSE => [FlxKey.ENTER          , FlxGamepadInputID.START     , FlxVirtualPadInputID.X ]
            , Action.CAM   => [FlxGamepadInputID.RIGHT_ANALOG_STICK, Mouse(Motion())]
            , Action.KEY   => [SPACE]
            ];
    }
}