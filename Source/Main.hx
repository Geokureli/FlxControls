package ;

import flixel.FlxG;
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
    var controls:Controls;
    override function create()
    {
        super.create();
        
        controls = new Controls("test");
        for (action in Action.createAll())
            FlxG.watch.addFunction(action.getName(), controls.pressed.check.bind(action));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.SPACE)
            controls.addKey(PAUSE, ENTER);
    }
}