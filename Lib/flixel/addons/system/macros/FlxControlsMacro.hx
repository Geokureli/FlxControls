package flixel.addons.system.macros;

import flixel.input.FlxInput;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.Tools;
using haxe.macro.TypeTools;

class FlxControlsMacro
{
    public static function buildControls():Array<Field>
    {   
        try
        {
            return buildControlsUnsafe();
        }
        catch(e)
        {
            Context.error(e.message, Context.currentPos());
        }
        
        return Context.getBuildFields();
    }
    
    public static function buildControlsUnsafe():Array<Field>
    {
        final fields = Context.getBuildFields();
        
        return switch Context.getLocalType()
        {
            // Extract the type parameter
            case TInst(local, _):
                
                final action = getAction(local.get());
                if (action == null)
                {
                    // Don't generate fields if actions is a type param
                    return fields;
                }
                
                final newFields = buildControlsFields(action);
                for (newField in newFields)
                    fields.push(newField);
                
                fields;
            case found:
                throw 'Expected TInst, found: $found';
        }
    }
    
    static function getAction(local:ClassType):EnumType
    {
        var superClass = local.superClass;
        do
        {
            if (superClass == null || superClass.t.get() == null)
                throw "class must extend flixel.addons.input.FlxControls";
            
            if (superClass.t.get().name != "flixel.addons.input.FlxControls")
                break;
            
            superClass = superClass.t.get().superClass;
        }
        while (true);
        
        return switch superClass.params
        {
            case [param]:
                switch param.follow()
                {
                    case TInst(_, _):
                        null;// No actual enum found (likely a type param)
                    case TEnum(type, []):
                        type.get();
                    case TEnum(t, params):
                        throw "Enums with type params are not allowed";
                    case found:
                        throw 'T must be an Enum type, found: $found';
                }
            case found:
                throw 'Expected <T:EnumValue>, found: $found';
        }
    }
    
    static function buildControlsFields(enumType:EnumType):Array<Field>
    {
        final listCT = buildActionList(enumType);
        return (macro class TempClass
        {
            public var pressed     (get, never):$listCT;
            public var released    (get, never):$listCT;
            public var justPressed (get, never):$listCT;
            public var justReleased(get, never):$listCT;
            
            @:noCompletion inline function get_pressed     () { return cast byStatus[$v{FlxInputState.PRESSED      }]; }
            @:noCompletion inline function get_released    () { return cast byStatus[$v{FlxInputState.RELEASED     }]; }
            @:noCompletion inline function get_justPressed () { return cast byStatus[$v{FlxInputState.JUST_PRESSED }]; }
            @:noCompletion inline function get_justReleased() { return cast byStatus[$v{FlxInputState.JUST_RELEASED}]; }
        }).fields;
    }
    
    static function buildActionList(enumType:EnumType):ComplexType
    {
        final name = 'FlxControlList__${enumType.pack.join("_")}_${enumType.name}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        // get full path to enum
        final fullEnumPath = enumType.module.split(".");
        fullEnumPath.push(enumType.name);
        
        final enumCT = Context.getType(fullEnumPath.join(".")).toComplexType();
        final baseTP:TypePath =
        {
            pack: ["flixel", "addons", "input"],
            name: "FlxControls",
            sub:"FlxControlList",
            params: [TPType(enumCT)]
        };
        
        // define the type
        final def = macro class $name { }
        def.kind = TDClass(baseTP);
        
        for (name in enumType.names)
        {
            final fields = createGetter(name, fullEnumPath);
            def.fields.push(fields[0]);
            def.fields.push(fields[1]);
        }
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
    }
    
    static function createGetter(name:String, enumPath:Array<String>):Array<Field>
    {
        final getterName = 'get_$name';
        final path = enumPath.copy();
        path.push(name);
        return (macro class TempClass
        {
            public var $name(get, never):Bool;
            @:noCompletion
            inline function $getterName () { return check($p{path}); }
        }).fields;
    }
}