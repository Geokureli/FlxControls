package ;

import haxe.Exception;
import utest.ui.Report;

class Main extends openfl.display.Sprite
{
    public function new()
    {
        super();
        
        addChild(new flixel.FlxGame(0, 0, BootState, 20, 20));
    }
}

class TestRunner extends utest.Runner
{
    public function new ()
    {
        super();
        addCase(new tests.TestMain());
    }
}

class BootState extends flixel.FlxState
{
    override function create()
    {
        final runner = new TestRunner();

        final report = Report.create(runner);
        report.displayHeader = AlwaysShowHeader;
        report.displaySuccessResults = NeverShowSuccessResults;

        var failed = false;
        runner.onProgress.add(function (r)
        {
            // if(!r.result.assertations.first().match())
            //     failed = true;
        });

        runner.run();

    }
        
    public function new(){ super(); }
}
