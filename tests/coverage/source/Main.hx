package ;

import flixel.addons.input.FlxControls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.ui.FlxVirtualPad;
import input.Controls;
import input.Controls2;

class Main extends openfl.display.Sprite
{
    public function new()
    {
        super();
        
        addChild(new flixel.FlxGame(0, 0, BootState2, 20, 20));
        // addChild(new flixel.FlxGame(0, 0, BootState, 20, 20));
    }
}


class BootState2 extends flixel.FlxState
{
    var controls:Controls2;
    var sprite:FlxSprite;
    
    override function create()
    {
        controls = new Controls2("test");
        #if (flixel < "5.9.0")
        FlxG.inputs.add(controls);
        #else
        FlxG.inputs.addInput(controls);
        #end
        
        controls.setGamepadID(FlxDeviceID.FIRST_ACTIVE);
        
        add(sprite = new FlxSprite(10, 10).makeGraphic(20, 20));
        sprite.origin.set(0, 0);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        final repeatMove = controls.repeat(0.2);
        final repeatColor = controls.repeat(0.1);
        final repeatMove = controls.MOVE.repeat(0.5);
        final repeatScale = controls.MOVE.repeat(0.5);
        #if (FLX_DEBUG && FlxControls.dev)
        // repeatMove.enableDebugWatchers = true;
        // repeatColor.enableDebugWatchers = true;
        controls.MOVE.enableDebugWatchers = true;
        #end
        
        if (repeatMove.L) sprite.x -= sprite.width;
        if (repeatMove.R) sprite.x += sprite.width;
        if (repeatMove.U) sprite.y -= sprite.height;
        if (repeatMove.D) sprite.y += sprite.height;
        if (repeatColor.any([U,D,L,R])) sprite.color = sprite.color == 0xFFffffff ? 0xFFff0000 : 0xFFffffff;
        
        // if (repeatMove.left ) sprite.x -= sprite.width;
        // if (repeatMove.right) sprite.x += sprite.width;
        // if (repeatMove.up   ) sprite.y -= sprite.height;
        // if (repeatMove.down ) sprite.y += sprite.height;
        
        if (repeatScale.left ) sprite.scale.x -= 1.0;
        if (repeatScale.right) sprite.scale.x += 1.0;
        if (repeatScale.up   ) sprite.scale.y -= 1.0;
        if (repeatScale.down ) sprite.scale.y += 1.0;
        
        if (sprite.scale.x < 1) sprite.scale.x = 1;
        if (sprite.scale.y < 1) sprite.scale.y = 1;
        sprite.width = sprite.scale.x * sprite.frameWidth;
        sprite.height = sprite.scale.y * sprite.frameHeight;
    }
}

class BootState extends flixel.FlxState
{
    override function create()
    {
        final controls = new Controls("test");
        #if (flixel < "5.9.0")
        FlxG.inputs.add(controls);
        #else
        FlxG.inputs.addInput(controls);
        #end
        
        for (action in Action.createAll())
            FlxG.log.add('$action groups: ${controls.groupsOf(action)}');
        
        FlxG.log.add(switch controls.addIfValid(DOWN, FlxKey.W)
        {
            case None: "W was added to DOWN";
            case Found(list): "W was not added to DOWN, conflicts: " + list.map((c)->'${c.group}:${c.action1}');
        });
        
        FlxG.log.add(switch controls.addIfValid(UP_2, FlxKey.W)
        {
            case None: "W was added to UP_2";
            case Found(list): "W was not added to UP_2, conflicts: " + list.map((c)->'${c.group}:${c.action1}');
        });
        
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
        FlxG.watch.addFunction("right-rp" , ()->controls.waitAndRepeat(0.5, 0.1).RIGHT );
        
        FlxG.watch.addFunction("cam-up" , ()->{
            // trace(controls.CAM.pressed);
            return controls.CAM.pressed.up;
        });
        FlxG.watch.addFunction("cam-down" , ()->controls.CAM.pressed.down ); 
        FlxG.watch.addFunction("cam-left" , ()->controls.CAM.pressed.left ); 
        FlxG.watch.addFunction("cam-right", ()->controls.CAM.pressed.right);
        FlxG.watch.addFunction("cam-up"   , ()->controls.CAM.pressed.up   );
        // FlxG.watch.addFunction("cam-right-rp", ()->controls.CAM.holdRepeat.right);
        
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