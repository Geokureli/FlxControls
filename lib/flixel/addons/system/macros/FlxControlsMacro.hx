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
        final enumDataList = ActionFieldData.listFromType(enumType);
        
        // Digital fields
        final listCT = buildDigitalActionList(enumType, enumDataList);
        final fields = (macro class TempClass
        {
            public var pressed     (get, never):$listCT;
            public var released    (get, never):$listCT;
            public var justPressed (get, never):$listCT;
            public var justReleased(get, never):$listCT;
            
            @:noCompletion inline function get_pressed     () { return cast listsByState[$v{FlxInputState.PRESSED      }]; }
            @:noCompletion inline function get_released    () { return cast listsByState[$v{FlxInputState.RELEASED     }]; }
            @:noCompletion inline function get_justPressed () { return cast listsByState[$v{FlxInputState.JUST_PRESSED }]; }
            @:noCompletion inline function get_justReleased() { return cast listsByState[$v{FlxInputState.JUST_RELEASED}]; }
        }).fields;
        
        /** Helper to concat without creating a new array */
        inline function pushAll(newFields:Array<Field>)
        {
            for (field in newFields)
                fields.push(field);
        }
        
        // Analog fields
        for (field in enumDataList)
        {
            switch field.controlType
            {
                case DIGITAL:
                case ANALOG(arg):
                    pushAll(field.createAnalog1DField(arg));
                case ANALOG_XY(argX, argY):
                    pushAll(field.createAnalog2DField(argX, argY));
            }
        }
        
        return fields;
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
        final name = 'FlxDigitalSet__${action.pack.join("_")}_${action.name}';
        
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
        final listCT = (macro: flixel.addons.input.FlxDigitalSet<$actionCT>);
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        def.kind = TDAbstract(listCT, [listCT], [listCT]);
        
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
            inline function $getterName () { return this.check($p{path}); }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    public function createAnalog1DField(arg:String):Array<Field>
    {
        // get or create the trigger type
        final typeCt = switch arg
        {
            case "amount":
                (macro: flixel.addons.input.FlxAnalogSet.FlxControlAnalog1D);
            case _:
                createAnalog1DType(arg);
        }
        
        final getterName = 'get_$name';
        final fields = (macro class TempClass
        {
            public var $name(get, never):$typeCt;
            @:noCompletion
            inline function $getterName () { return analogs.get($p{path}); }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    static function createAnalog1DType(arg:String)
    {
        final name = 'FlxControlAnalog1D__$arg';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final getterName = 'get_$arg';
        
        // define the type
        final def = (macro class $name
        {
            /** The value of this trigger **/
            public var $arg(get, never):Float;
            public function $getterName():Float return this.x;
        });
        
        // def.meta.push({ name:":forward", pos:Context.currentPos() });
        
        final controlType = (macro: flixel.addons.input.FlxAnalogSet.FlxControlAnalogBase1D);
        def.kind = TDAbstract(controlType, [controlType], [controlType]);
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
    }
    
    public function createAnalog2DField(argX:String, argY:String):Array<Field>
    {
        // get or create the joystick type
        final typeCt = switch [argX, argY]
        {
            case ["x", "y"]:
                (macro: flixel.addons.input.FlxAnalogSet.FlxControlAnalog2D);
            case _:
                createAnalog2DType(argX, argY);
        }
        
        final getterName = 'get_$name';
        final fields = (macro class TempClass
        {
            public var $name(get, never):$typeCt;
            @:noCompletion
            inline function $getterName () { return cast analogSet.get($p{path}); }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    static function createAnalog2DType(argX:String, argY:String)
    {
        final name = 'FlxControlAnalog2D__${argX}_${argY}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final getterX = 'get_$argX';
        final getterY = 'get_$argY';
        
        // define the type
        final def = (macro class $name
        {
            /** The horizontal component of this joystick **/
            public var $argX(get, never):Float;
            inline function $getterX():Float { return this.getX(); }
            
            /** The vertical component of this joystick **/
            public var $argY(get, never):Float;
            inline function $getterY():Float { return this.getY(); }
        });
        
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        
        final controlType = (macro: flixel.addons.input.FlxAnalogSet.FlxControlAnalogBase2D);
        def.kind = TDAbstract(controlType, [controlType], [controlType]);
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
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