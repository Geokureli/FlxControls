package tests;

import flixel.addons.input.FlxControls;
import flixel.input.keyboard.FlxKey;
import utest.Assert;

using Lambda;

class TestMain extends utest.Test
{
    var controls:Controls;
    public function setup()
    {
        controls = new Controls();
    }
    
    function testDefaultMappings()
    {
        Assert.isTrue (controls.listInputsFor(UP  ).exists((i)->i.compare(FlxKey.W)));
        Assert.isTrue (controls.listInputsFor(DOWN).exists((i)->i.compare(FlxKey.S)));
        Assert.isFalse(controls.listInputsFor(UP  ).exists((i)->i.compare(FlxKey.S)));
        Assert.isFalse(controls.listInputsFor(DOWN).exists((i)->i.compare(FlxKey.W)));
    }
    
    function testGroups()
    {
        Assert.isTrue (controls.groupsOf(UP  ).contains("vertical"));
        Assert.isTrue (controls.groupsOf(DOWN).contains("vertical"));
    }
    
    function testAddIfValid()
    {
        controls.addIfValid(UP, FlxKey.S);
        Assert.isFalse(controls.listInputsFor(UP).exists((i)->i.compare(FlxKey.S)));
    }
    
    public function teardown()
    {
        controls.destroy();
    }
}

enum Action
{
    @:group("vertical")
    UP;
    @:group("vertical")
    DOWN;
}

class Controls extends flixel.addons.input.FlxControls<Action>
{
    function getDefaultMappings():ActionMap<Action>
    {
        return
            [ UP   => [ FlxKey.W ]
            , DOWN => [ FlxKey.S ]
            ];
    }
}