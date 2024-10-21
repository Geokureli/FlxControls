package input;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.addons.input.FlxControlInputType.FlxVirtualPadInputID as VPad;
import flixel.input.gamepad.FlxGamepadInputID as GPad;
import flixel.input.keyboard.FlxKey as Key;

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Action
{
    /** Moves the player up, also used to navigate menus */
    @:inputs([Key.UP   , Key.W, DPAD_UP   , LEFT_STICK_DIGITAL_UP   , VPad.UP    ]) UP;
    /** Moves the player down, also used to navigate menus */
    @:inputs([Key.DOWN , Key.S, DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN , VPad.DOWN  ]) DOWN;
    /** Moves the player left, also used to navigate menus */
    @:inputs([Key.LEFT , Key.A, DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT , VPad.LEFT  ]) LEFT;
    /** Moves the player right, also used to navigate menus */
    @:inputs([Key.RIGHT, Key.D, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, VPad.RIGHT ]) RIGHT;
    /** Makes the player jump */
    @:inputs([Key.L    , Key.X, GPad.A    , VPad.B ])                               JUMP;
    /** Makes the player shoot */
    @:inputs([Key.K    , Key.Z, GPad.X    , VPad.Y ])                               SHOOT;
    /** Used to select options in the menu */
    @:inputs([Key.K    , Key.Z, GPad.A    , VPad.A ])                               ACCEPT;
    /** Used to cancel or exit a menu */
    @:inputs([Key.L    , Key.X, GPad.B    , VPad.B ])                               BACK;
    /** Pauses the game */
    @:inputs([Key.ENTER       , START     , VPad.X ])                               PAUSE;
    /** A test action */
    @:inputs([SPACE])                                                               KEY;
    @:inputs([RIGHT_ANALOG_STICK, Mouse(Motion())])                 @:analog(x, y)  CAM;
    @:inputs([Mouse(Motion(X))])                                    @:analog(value) GAS;
    @:inputs([Mouse(Motion(Y))])                                    @:analog(value) BREAKS;
}

class Controls extends FlxControls<Action>
{
    // function getDefaultMappings():ActionMap<Action>
    // {
    //     return
    //         [ Action.UP    => [Key.UP   , Key.W, GPad.DPAD_UP   , GPad.LEFT_STICK_DIGITAL_UP   , VPad.UP    ]
    //         , Action.DOWN  => [Key.DOWN , Key.S, GPad.DPAD_DOWN , GPad.LEFT_STICK_DIGITAL_DOWN , VPad.DOWN  ]
    //         , Action.LEFT  => [Key.LEFT , Key.A, GPad.DPAD_LEFT , GPad.LEFT_STICK_DIGITAL_LEFT , VPad.LEFT  ]
    //         , Action.RIGHT => [Key.RIGHT, Key.D, GPad.DPAD_RIGHT, GPad.LEFT_STICK_DIGITAL_RIGHT, VPad.RIGHT ]
    //         , Action.JUMP  => [Key.L    , Key.X, GPad.A         , VPad.B ]
    //         , Action.SHOOT => [Key.K    , Key.Z, GPad.X         , VPad.Y ]
    //         , Action.ACCEPT=> [Key.K    , Key.Z, GPad.A         , VPad.A ]
    //         , Action.BACK  => [Key.L    , Key.X, GPad.B         , VPad.B ]
    //         , Action.PAUSE => [Key.ENTER          , GPad.START     , VPad.X ]
    //         , Action.CAM   => [GPad.RIGHT_ANALOG_STICK, Mouse(Motion())]
    //         , Action.GAS   => [Mouse(Motion(X))]
    //         , Action.BREAKS=> [Mouse(Motion(Y))]
    //         , Action.KEY   => [SPACE]
    //         ];
    // }
}