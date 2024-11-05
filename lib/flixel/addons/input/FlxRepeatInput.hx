package flixel.addons.input;

class FlxRepeatInput<T> extends flixel.input.FlxInput<T>
{
    inline static var INITIAL_DELAY = 0.5;
    inline static var REPEAT_DELAY = 0.1;
    
    var timer:Float = 0;
    var repeatTriggered = false;
    
    public function triggerRepeat():Bool
    {
        return repeatTriggered;
    }
    
    public function updateWithState(isPressed:Bool)
    {
        repeatTriggered = false;
        if (pressed)
        {
            timer += FlxG.elapsed;
            repeatTriggered = timer >= REPEAT_DELAY;
            if (repeatTriggered)
                timer -= REPEAT_DELAY;
        }
        
        if (isPressed && released)
        {
            press();
            timer = REPEAT_DELAY - INITIAL_DELAY;
            repeatTriggered = true;
        }
        
        if (!isPressed && pressed)
        {
            release();
            timer = 0;
        }
        
        update();
    }
}