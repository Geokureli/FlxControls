package ;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.ui.FlxVirtualPad;
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
    override function create()
    {
        final controls = new Controls("test");
        FlxG.inputs.addInput(controls);
        
        // @:privateAccess
        // final testMap = controls.getDefaultMappings();
        // for (action=>inputs in testMap)
        //     trace('action: $action => inputs: $inputs');
        
        final pad = new FlxVirtualPad(FULL, A_B_X_Y);
        controls.setVirtualPad(pad);
        add(pad);
        
        // Can also check using helper properties generated for each action
        FlxG.watch.addFunction("up"    , ()->controls.pressed.UP    );
        FlxG.watch.addFunction("down"  , ()->controls.pressed.DOWN  );
        FlxG.watch.addFunction("left"  , ()->controls.pressed.LEFT  );
        FlxG.watch.addFunction("right" , ()->controls.pressed.RIGHT );
        FlxG.watch.addFunction("jump"  , ()->controls.pressed.JUMP  );
        FlxG.watch.addFunction("shoot" , ()->controls.pressed.SHOOT );
        FlxG.watch.addFunction("accept", ()->controls.pressed.ACCEPT);
        FlxG.watch.addFunction("back"  , ()->controls.pressed.BACK  );
        FlxG.watch.addFunction("pause" , ()->controls.pressed.PAUSE );
        
        // // Check if multiple actions are pressed like so:
        FlxG.watch.addFunction("l/r"   , ()->controls.pressed.any([LEFT, RIGHT]));
        FlxG.watch.addFunction("u/d"   , ()->controls.pressed.any([UP, DOWN]));
        
        FlxG.watch.addFunction("cam"   , function ()
        {
            final p = controls.CAM;
            return '${p.x} | ${p.y}';
        });
    }
}