# FlxControls
A simplified multi-device input manager tools for HaxeFlixel

![](images/code_hinting.png)

Allows you to easily define all possible player actions, whether the action represents digital or analog data and what device inputs each action is mapped to, by default. As shown above, extending FlxControls causes macros to generate handy fields for each action.

## Digital Actions
Using the ["Bare" sample](samples/Bare/source/Action.hx) as an example, `UP`, `DOWN`, `LEFT` and `RIGHT` are digital actions, as they are tied to things like gamepad buttons or keyboard keys. Digital actions create fields which can be used to check the status of actions, like so:
```hx
// same as controls.checkDigital(DOWN, PRESSED);
controls.pressed.DOWN
// same as controls.checkDigital(DOWN, JUST_PRESSED);
controls.justPressed.DOWN
// same as controls.checkDigital(DOWN, RELEASED);
controls.released.DOWN
// same as controls.checkDigital(DOWN, JUST_RELEASED);
controls.justReleased.DOWN
```

### Hold Repeat Events
In addition to the typical digital input states, above, there is also a 5th event type called "hold repeat" which behaves similarly to typing. It fires when the action is first pressed, but after 0.5 seconds it will fire every 0.1 seconds. This is common behavior for menu navigation
```hx
// same as controls.checkDigital(DOWN, REPEAT);
controls.holdRepeat.DOWN
```

## Analog actions
Actions can be tied to analog inputs as well, such as a joystick, a trigger or the mouse position. Using the ["Bare" sample](samples/Bare/source/Action.hx) as an example, once again, `MOVE`, `LEFT_TRIGGER` and `RIGHT_TRIGGER` are analog actions. Their values can be accessed like so:
```hx
// will be a value from 0.0 to 1.0
controls.TRIGGER_LEFT.value
controls.TRIGGER_RIGHT.value
// will be a value from -1.0 to 1.0 from the gamepad's analog stick,
// but can be higher or lower by moving the mouse fast enough
controls.MOVE.x
controls.MOVE.y
```

### Creating Analog Actions from Digital Inputs
Four digital inputs can be used to create a 2D analog input, allowing keys like W,A,S and D to function similarly to a gamepad's joystick, where pressing them can set the corresponding x and y values to `-1` or `1`. Similarly, 2 digital inputs can create a 1D analog input. Check out the ["FlxCamera" demo](samples/FlxCamera/source/input/PlayerControls.hx#L44-L50) for an example.

### Creating Digital Sub-actions from Analog Actions
Just as 4 digital directional inputs can be used to create a 2D analog action, All 2D analog actions have 4 directional sub-actions. For instance say the action `MOVE` is tied to a gamepad's joystick, when the stick is moved forward (making the `y` value postive) `controls.MOVE.pressed.up` will be true. Similarly, 1D actions will have `up` and `down` sub-actions.

Just like digital actions, these directional sub-actions have `pressed`, `released`, `justPressed`, `justReleased` and `holdRepeat` fields

## Setuping up the Default Input Mappings
There are two ways to setup your control's default mapping: 1. Add the meta `@:inputs([...])` to each value of your enum action. Each with an array of different inputs. Check out the ["Bare" sample](samples/Bare/source/Action.hx) for an example 2. In your class extending FlxControls, define `function getDefaultMappings():ActionMap<MyAction>` and have it return a map that links actions to an array of inputs. Check the ["FlxCamera" sample](samples/FlxCamera/source/input/PlayerControls.hx#L41-L52) for an example.

### Defining Input Arrays for Mappings
The aforementioned input arrays are very flexible, you can list any `FlxKey`, `FlxGamepadInputID`, `FlxMouseButtonID` or `FlxVirtualPadInputID`. Here are some examples for each input device:
- Keyboard: Can specify key inputs via `FlxKey.A`, or unique keys like `ENTER` or `H` can be used, unqualified, since there is no H input on any other device. Using a `FlxKey` directly - like above - is short-hand for `Keyboard(Lone(A))`, which is also acceptible. 2D multi-key analog inputs can be added via `Keyboard(Multi(W, S, D, A))`, though you can shorten this by using [import aliases](samples/FlxCamera/source/input/PlayerControls.hx#L6). There are also helpers for common directional keys, like `WASD` and `Keyboard(Arrows)`
- Gamepad: Can specify gamepad inputs via `FlxGamepadInputID.A`, or unqique things like `DPAD_UP` can be used, unqualified. Using a `FlxGamepadInputID` directly - like above - is short-hand for `Gamepad(Lone(A))`, which is also acceptible. 2D multi-button analog inputs can be added via `Gamepad(Multi(Y, A, B, X))`, though you can shorten this by using [import aliases](samples/FlxCamera/source/input/PlayerControls.hx#L9). There are also helpers for common directional buttons, like `DPAD` and `FACE` (AKA: ABXY buttons)
- Mouse: Can specify button inputs via `FlxMouseButtonID.LEFT`, or `MIDDLE` can be used, unqualified. Using a `FlxMouseButtonID` directly - like above - is short-hand for `Mouse(Lone(LEFT))`, which is also acceptible. Analog mouse inputs are specified via `Mouse(Position())`, `Mouse(Motion())`, `Mouse(Drag())` or `Mouse(Wheel())`. Some of these allow you to specify a single axis (2D is the default) and a scale, in addition to other properties
- Virtual Pad: Virtual pad inputs behave identical to Keyboard inputs, but with `FlxVirtualPadInputID` values rather than `FlxKey`. It also has a helper for analog `Arrows`

## Changing Input Mappings at runtime
`FlxControls` supports re-mapping inputs using the `add` and `remove` methods, which take the target action and an input which is specfied the same way they were in the default map. Currently, there is no built-in save system or helper for re-mapped controls. You'll need to make that yourself as well as any UI for allowing the user to remap controls, but both of these are planned.

## Multiple Gamepads
You can make multiple instances of `FlxControls` where each instance uses a different gamepad. By default `FlxControls` uses the first connected gamepad. Use `setGamepadID(ALL)` to use all gamepads, or `setGamepadID(myGamepad.id)` to use a specific gamepad. Currently, there is no way to make the keyboard and/or mouse only work for one instance without specifically removing each input of that device, though, a per device toggle is planned.

## Displaying Input Labels to the User
To get a list of strings that represent each input tied to a specific action, use `listInputLabelsFor(MyAction)` and if desired, specify a device to limit this list. To get the labels for whichever device is actively being used, use `controls.listInputLabelsFor(MyAction, controls.lastActiveDevice)`. For gamepads the label returned will actually be the specific label of that gamepad model, not just the generic gamepad input id. Non-english keyboards will return the label of whatever key is located there on the English equivalent. In the future, it's planned to actually get the label of that key based on your keyboards layout. For multi input analog inputs a string containing all the inputs is returned.

If using Flixel 5.9.0, there is a `listMappedInputsFor` method, which, instead of returning labels, it returns an enum containing every possible input from every possible device. For gamepads it will use identifiers such as `WII_REMOTE(A)` or `PS4(SQUARE)`. For keyboard, The Result looks very similar to the input mappings passed in, for "Multi button" analog inputs like `Face`, the result is something like:
```hx
Gamepad(Multi([PS4(TRIANGLE), PS4(X), PS4(CIRCLE), PS4(SQUARE)]))
```
These ids can be used to create custom labels or display a specific image of that input.

## To Dos
- Schema for saving input mappings
- Example input remapping UI
- Add way to disable keyboard and mouse for specific instances of `FlxControls`
- Add way to get key labels for non-english keyboards
- Map each `FlxControlMappedInput` to an image in [Kenney's input prompts](https://www.kenney.nl/assets/input-prompts)