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
        
        addChild(new flixel.FlxGame(0, 0, BootState, 4, 4));
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
        
        FlxG.watch.addFunction("cam-up" , ()->{
            // trace(controls.CAM.pressed);
            return controls.CAM.pressed.up;
        });
        FlxG.watch.addFunction("cam-down" , ()->controls.CAM.pressed.down);
        FlxG.watch.addFunction("cam-left" , ()->controls.CAM.pressed.left);
        FlxG.watch.addFunction("cam-right" , ()->controls.CAM.pressed.right);
        
        // // Check if multiple actions are pressed like so:
        FlxG.watch.addFunction("l/r"   , ()->controls.pressed.any([LEFT, RIGHT]));
        FlxG.watch.addFunction("u/d"   , ()->controls.pressed.any([UP, DOWN]));
        
        controls.GAS.vroom;
        controls.BREAKS.value;
        
        FlxG.watch.addFunction("cam2"   , function ()
        {
            final p = controls.CAM2;
            return '${p.x2} | ${p.y2}';
        });
        FlxG.watch.addFunction("cam"   , function ()
        {
            final p = controls.CAM;
            return '${p.x} | ${p.y}';
        });
        FlxG.watch.addFunction("lastActive", ()->controls.lastActiveDevice.getName());
    }
}