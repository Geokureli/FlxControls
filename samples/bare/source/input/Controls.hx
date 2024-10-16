package input;

import flixel.addons.input.FlxControls;
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
    @:button(LEFT_STICK_DIGITAL_UP, DPAD_UP)
    @:key(UP, W)
    @:pad(UP)
    UP;
    
    /** Moves the player down, also used to navigate menus */
    @:button(LEFT_STICK_DIGITAL_DOWN, DPAD_DOWN)
    @:key(DOWN , S)
    @:pad(DOWN)
    DOWN;
    
    /** Moves the player left, also used to navigate menus */
    @:button(LEFT_STICK_DIGITAL_LEFT, DPAD_LEFT)
    @:key(LEFT , A)
    @:pad(LEFT)
    LEFT;
    
    /** Moves the player right, also used to navigate menus */
    @:button(LEFT_STICK_DIGITAL_RIGHT, DPAD_RIGHT)
    @:key(RIGHT, D)
    @:pad(RIGHT)
    RIGHT;
    
    /** Makes the player jump */
    @:button(A)
    @:key(L, X)
    @:pad(A)
    JUMP;
    
    /** Makes the player shoot */
    @:button(Y)
    @:key(K, Z)
    @:pad(Y)
    SHOOT;
    
    /** Used to select options in the menu */
    @:button(A)
    @:key(K, Z)
    @:pad(A)
    ACCEPT;
    
    /** Used to cancel or exit a menu */
    @:button(B)
    @:key(L, X)
    @:pad(B)
    BACK;
    
    /** Pauses the game */
    @:button(START)
    @:key(ENTER)
    @:pad(X)
    PAUSE;
    
    /** A test action */
    @:key(SPACE)
    KEY;
    
    @:analog(x, y)
    MOVE;
}

class Controls extends flixel.addons.input.FlxControls<Action>
{
    function getDefaultMappings():ActionMap<Action>
    {
        return
            [ Action.UP    => [FlxKey.UP   , FlxKey.W, FlxGamepadInputID.DPAD_UP   , FlxGamepadInputID.LEFT_STICK_DIGITAL_UP    ]
            , Action.DOWN  => [FlxKey.DOWN , FlxKey.S, FlxGamepadInputID.DPAD_DOWN , FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN  ]
            , Action.LEFT  => [FlxKey.LEFT , FlxKey.A, FlxGamepadInputID.DPAD_LEFT , FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT  ]
            , Action.RIGHT => [FlxKey.RIGHT, FlxKey.D, FlxGamepadInputID.DPAD_RIGHT, FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT ]
            , Action.JUMP  => [FlxKey.L    , FlxKey.X, FlxGamepadInputID.A         ]
            , Action.SHOOT => [FlxKey.K    , FlxKey.Z, FlxGamepadInputID.B         ]
            , Action.ACCEPT=> [FlxKey.K    , FlxKey.Z, FlxGamepadInputID.A         ]
            , Action.BACK  => [FlxKey.L    , FlxKey.X, FlxGamepadInputID.B         ]
            // odd-balls
            , Action.PAUSE => [FlxGamepadInputID.START]
            , Action.MOVE  => [FlxGamepadInputID.LEFT_ANALOG_STICK, Mouse(Motion())]
            , Action.KEY   => [SPACE]
            ];
    }
}