package flixel.addons.system.macros;

import flixel.input.FlxInput;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.Tools;
using haxe.macro.TypeTools;
using flixel.addons.system.macros.FlxControlsMacro.MacroUtils;

class FlxControlsMacro
{
    public static function buildControls():Array<Field>
    {
        #if (FlxControls.verboseMacroErrors)
        return buildControlsUnsafe(); // raw dog it
        #else
        try
        {
            return buildControlsUnsafe();
        }
        catch(e)
        {
            Context.error(e.message, Context.currentPos());
            return Context.getBuildFields();
        }
        #end
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
        final enumFields = ActionFieldData.listFromType(enumType);
        
        // Digital fields
        final listCT = buildDigitalActionList(enumType, enumFields);
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
        
        // Analog fields
        // for (field in parsedEnumFields)
        // {
        //     switch field.controlType
        //     {
        //         case DIGITAL:
        //         case ANALOG(arg):
        //         case ANALOG_XY(argX, argY):
        //     }
        // }
        
        // return fields;
    }
    
    static function buildAnalogActions(action:EnumType, field:EnumField):ComplexType
    {
        final name = 'FlxControlAnalog__${action.pack.join("_")}_${action.name}__${field.name}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        return null;
    }
    
    static function buildDigitalActionList(action:EnumType, enumFields:Array<ActionFieldData>):ComplexType
    {
        final name = 'FlxControlList__${action.pack.join("_")}_${action.name}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final actionCT = Context.getType(action.module + "." + action.name).toComplexType();
        // define the type
        final def = macro class $name { }
        def.kind = TDClass
        ({
            pack: ["flixel", "addons", "input"],
            name: "FlxControls",
            sub:"FlxControlList",
            params: [TPType(actionCT)]
        });
        
        for (field in enumFields)
        {
            switch field.controlType
            {
                case DIGITAL:
                    final fields = field.createDigitalGetter();
                    def.fields.push(fields[0]);
                    def.fields.push(fields[1]);
                case ANALOG(_):
                case ANALOG_XY(_, _):
            }
        }
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
    }
}

private class MacroUtils
{
    inline overload extern static public function getAllValidMetas(meta, name:String, validList, addColon = true, addS = true)
    {
        final list = new Array<String>();
        addAllValidMetas(list, meta, name, validList, addColon, addS);
        return list;
    }
    
    inline overload extern static public function getAllValidMetas(meta, names:Array<String>, validList, addColon = true, addS = true)
    {
        final list = new Array<String>();
        for (name in names)
            addAllValidMetas(list, meta, name, validList, addColon, addS);
        return list;
    }
    
    static public function addAllValidMetas(list, meta, name:String, validList, addColon = true, addS = true)
    {
        addAllValidMeta(list, meta, name, validList);
        if (addColon)
            addAllValidMeta(list, meta, ":" + name, validList);
        if (addS)
            addAllValidMeta(list, meta, name + "s", validList);
        if (addColon && addS)
            addAllValidMeta(list, meta, ":" + name + "s", validList);
    }
    
    static function addAllValidMeta(list:Array<String>, meta:MetaAccess, name:String, validList:Array<String>)
    {
        for (entry in meta.extract(name))
        {
            for (param in entry.params)
            {
                switch(param.expr)
                {
                    case EConst(CIdent(name)) if (validList.contains(name.toUpperCase())):
                        list.push(name.toUpperCase());
                    case EConst(CIdent(found)):
                        throw 'Invalid @$name arg, found $found expecting: [${validList.join(", ")}]';
                    case found:
                        throw 'Invalid @$name arg, found $found expecting: [${validList.join(", ")}]';
                }
            }
        }
    }
}

@:structInit
class ActionFieldData
{
    public var name:String;
    public var path:Array<String>;
    public var controlType:ActionType;
    public var defaultKeys:Array<String>;
    public var defaultGPad:Array<String>;
    public var defaultVPad:Array<String>;
    public var doc:String;
    
    static final validKeys = getAbstractEnumNames("flixel.input.keyboard.FlxKey");
    static final validButtons = getAbstractEnumNames("flixel.input.gamepad.FlxGamepadInputID");
    static final validPads = ["UP", "DOWN", "LEFT", "RIGHT", "A", "B", "C", "X", "Y"];
    static public function fromConstruct(action:EnumField, type:EnumType):ActionFieldData
    {
        final path = getPath(action, type);
        final controlType = getControlType(action);
        final keys = action.meta.getAllValidMetas("key", validKeys);
        final gPad = action.meta.getAllValidMetas("button", validButtons);
        final vPad = action.meta.getAllValidMetas("pad", validPads);
        
        return
            { name       : action.name
            , path       : path
            , controlType: controlType
            , defaultKeys: keys
            , defaultGPad: gPad
            , defaultVPad: vPad
            , doc        : action.doc
            };
    }
    
    public function createDigitalGetter():Array<Field>
    {
        final getterName = 'get_$name';
        final fields = (macro class TempClass
        {
            public var $name(get, never):Bool;
            @:noCompletion
            inline function $getterName () { return check($p{path}); }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    static function getType(field:EnumField)
    {
        return switch(field.type)
        {
            case TEnum(t, _): t.get();
            case found:
                throw 'Unhandled action type on ${field.name}, found: $found';
        }
    }
    
    inline static function getPath(action:EnumField, ?type:EnumType)
    {
        final path = (type ?? getType(action)).module.split(".");
        path.push(type.name);
        path.push(action.name);
        return path;
    }
    
    static public function listFromType(enumType:EnumType):Array<ActionFieldData>
    {
        return
        [
            for (name => construct in enumType.constructs)
            {
                if (construct == null)
                    throw 'Could not find action by name: $name';
                
                fromConstruct(construct, enumType);
            }
        ];
    }
    
    inline static var META = ":analog";
    static function getControlType(action:EnumField)
    {
        final construct = action;
        return switch(construct.type)
        {
            case TEnum(_, []) if (construct.meta.extract(META).length > 1):
                throw 'Found multiple @$META tags, expected one';
            case TEnum(_, []) if (construct.meta.has(META)):
                switch(construct.meta.extract(META)[0].params)
                {
                    case [arg]:
                        switch(arg.expr)
                        {
                            case EConst(CIdent(name)):
                                ANALOG(name);
                            case found:
                                throw 'Invalid @$META arg, expected an identifier, found $found';
                        }
                    case [argX, argY]:
                        switch([argX.expr, argY.expr])
                        {
                            case [EConst(CIdent(nameX)), EConst(CIdent(nameY))]:
                                ANALOG_XY(nameX, nameY);
                            case [foundX, foundY]:
                                throw 'Invalid @$META arg, expected an identifier, found ($foundX, $foundY) ';
                        }
                    case found:
                        throw 'Invalid @$META args, expected length of 1 or 2, found: @$META(${found})';
                }
            case TEnum(_, []):
                DIGITAL;
            case TFun(args, _):
                throw 'Enums with args are not allowed, found: ${action.name}(...)';
            case found:
                throw 'Unhandled action type on ${action.name}, found: $found';
        };
    }
    
    static function getAbstractEnumNames(typePath:String):Array<String>
    {
        final type = Context.getType(typePath);

        // Switch on the type and check if it's an abstract with @:enum metadata
        switch (type.follow())
        {
            case TAbstract(_.get() => ab, _) if (ab.meta.has(":enum")):
                // @:enum abstract values are actually static fields of the abstract implementation class,
                // marked with @:enum and @:impl metadata. We generate an array of expressions that access those fields.
                // Note that this is a bit of implementation detail, so it can change in future Haxe versions, but it's been
                // stable so far.
                final names = new Array<String>();
                for (field in ab.impl.get().statics.get())
                {
                    if (field.meta.has(":enum") && field.meta.has(":impl"))
                        names.push(field.name);
                }
                // Return collected expressions as an array declaration.
                return names;
            default:
                // The given type is not an abstract, or doesn't have @:enum metadata, show a nice error message.
                throw '$type should be @:enum abstract';
        }
    }
}

enum ActionType
{
    DIGITAL;
    ANALOG(arg:String);
    ANALOG_XY(argX:String, argY:String);
}