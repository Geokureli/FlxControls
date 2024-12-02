package flixel.addons.system.macros;

// import flixel.input.FlxInput;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using haxe.macro.Tools;
using haxe.macro.TypeTools;

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
                
                // Don't generate fields if actions is a type param
                if (action != null)
                    addControlsFields(action, fields);
                
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
    
    static function addControlsFields(enumType:EnumType, fields:Array<Field>)
    {
        final enumDataList = ActionFieldData.listFromType(enumType);
        if (enumDataList.length == 0)
            return;
        
        // add digital and analog action helpers
        final newFields = buildControlsFields(enumType, enumDataList);
        for (newField in newFields)
            fields.push(newField);
        
        // check for default mappings
        final existingMapField = fields.find((f)->f.name == "getDefaultMappings");
        final foundDefaults = enumDataList.exists((action)->action.hasDefaults());
        // generate default mappings, if possible
        if ((existingMapField == null || existingMapField.access.contains(AOverride)) && foundDefaults)
        // if (foundDefaults)
        {
            fields.push(buildDefaultMapField(enumDataList));
        }
        
        // check for groups
        if (enumDataList.exists((action)->action.hasGroups()))
        {
            fields.push(buildInitGroupsField(enumDataList));
        }
    }
    
    static function buildControlsFields(enumType:EnumType, enumDataList:Array<ActionFieldData>):Array<Field>
    {
        #if (FlxControls.useSimpleDigital)
        final actionCT = Context.getType(enumType.module + "." + enumType.name).toComplexType();
        final digitalSetCT = (macro: flixel.addons.input.FlxDigitalSet<$actionCT>);
        #else
        final digitalSetCT = buildDigitalSet(enumType, enumDataList);
        // final analogSetCT = buildAnalogSet(enumType, enumDataList);
        #end
        // Digital fields
        final fields = (macro class TempClass
        {
            /** Whether the action is currently pressed */
            public var pressed     (get, never):$digitalSetCT;
            
            /** Whether the action is currently released */
            public var released    (get, never):$digitalSetCT;
            
            /** Whether the action was pressed in the last frame */
            public var justPressed (get, never):$digitalSetCT;
            
            /** Whether the action was released in the last frame */
            public var justReleased(get, never):$digitalSetCT;
            
            /** Similar to `justPressed` but holding the input for 0.5s will make it fire every 0.1s */
            public var holdRepeat  (get, never):$digitalSetCT;
            
            @:noCompletion inline function get_pressed     () { return cast digitalSets[flixel.addons.input.FlxControls.DigitalEvent.PRESSED      ]; }
            @:noCompletion inline function get_released    () { return cast digitalSets[flixel.addons.input.FlxControls.DigitalEvent.RELEASED     ]; }
            @:noCompletion inline function get_justPressed () { return cast digitalSets[flixel.addons.input.FlxControls.DigitalEvent.JUST_PRESSED ]; }
            @:noCompletion inline function get_justReleased() { return cast digitalSets[flixel.addons.input.FlxControls.DigitalEvent.JUST_RELEASED]; }
            @:noCompletion inline function get_holdRepeat  () { return cast digitalSets[flixel.addons.input.FlxControls.DigitalEvent.REPEAT       ]; }
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
    
    static function buildDigitalSet(action:EnumType, enumFields:Array<ActionFieldData>):ComplexType
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
        
        
        // define the type
        final def = macro class $name { }
        final actionCT = enumFields[0].actionCT;
        final listCT = (macro: flixel.addons.input.FlxDigitalSet<$actionCT>);
        def.kind = TDAbstract(listCT, [listCT], [listCT]);
        
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        
        for (field in enumFields)
        {
            switch field.controlType
            {
                case DIGITAL:
                    final fields = field.createGetter();
                    def.fields.push(fields[0]);
                    def.fields.push(fields[1]);
                case ANALOG(_):
                case ANALOG_XY(_, _):
            }
        }
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
    }
    
    static function buildAnalogSet(action:EnumType, enumFields:Array<ActionFieldData>):ComplexType
    {
        final name = 'FlxAnalogSet__${action.pack.join("_")}_${action.name}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({pack: [], name: name});
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final actionCT = enumFields[0].actionCT;
        // define the type
        final def = macro class $name { }
        final listCT = (macro: flixel.addons.input.FlxAnalogSet<$actionCT>);
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        def.kind = TDAbstract(listCT, [listCT], [listCT]);
        
        for (field in enumFields)
        {
            switch field.controlType
            {
                case DIGITAL:
                case ANALOG(_) | ANALOG_XY(_, _):
                    final fields = field.createGetter();
                    def.fields.push(fields[0]);
                    def.fields.push(fields[1]);
            }
        }
        
        Context.defineType(def);
        return TPath({pack: [], name: name});
    }
    
    static function buildDefaultMapField(actions:Array<ActionFieldData>):Field
    {
        final actionCT = actions[0].actionCT;
        final mapCT = (macro: flixel.addons.input.FlxControls.ActionMap<$actionCT>);
        // Only add filters with default inputs set
        final actions = actions.filter((a)->a.hasDefaults());
        return (macro class TempClass
        {
            function getDefaultMappings():$mapCT
            {
                // return null;
                return $a{actions.map((action) -> return macro $p{action.path} => $a{action.inputs})};
            }
        }).fields[0];
    }
    
    static function buildInitGroupsField(actions:Array<ActionFieldData>):Field
    {
        // Map each group to the actions it contains
        final groups:Map<String, Array<ActionFieldData>> = [];
        for (action in actions)
        {
            for (group in action.groups)
            {
                if (groups.exists(group) == false)
                    groups[group] = [];
                
                groups[group].push(action);
            }
        }
        
        final exprBlock = [for (name=>actions in groups)
        {
            macro groups[$v{name}] = $a{actions.map((action) -> return macro $p{action.path})};
        }];
        
        return (macro class TempClass
        {
            override function initGroups()
            {
                $b{exprBlock};
            }
        }).fields[0];
    }
}

@:structInit
class ActionFieldData
{
    public var name:String;
    public var path:Array<String>;
    public var actionCT:ComplexType;
    public var controlType:ActionType;
    public var inputs:Array<Expr>;
    public var groups:Array<String>;
    public var doc:String;
    
    static public function fromConstruct(action:EnumField, type:EnumType):ActionFieldData
    {
        final inputs = getInputs(action.meta.extract(":inputs"));
        return
            { name       : action.name
            , path       : getPath(action, type)
            , actionCT   : Context.getType(type.module + "." + type.name).toComplexType()
            , controlType: getControlType(action)
            , inputs     : getInputs(action.meta.extract(":inputs"))
            , groups     : getGroups(action.meta.extract(":group"))
            , doc        : action.doc
            };
    }
    
    static function getInputs(inputs:Array<MetadataEntry>):Array<Expr>
    {
        switch inputs
        {
            case [input]:
                switch input.params
                {
                    case [param]:
                        switch param.expr
                        {
                            case EArrayDecl(values):
                                return values;
                            case found:
                                throw('Expected one parameter with an array of inputs on @:inputs meta, found: [${found.getName()}]');
                        }
                    case found:
                        throw('Expected one parameter with an array of inputs on @:inputs meta, found: ${found.map((p)->p.expr.getName())}');
                }
                return null;
            case []:
                return null;
            case found:
                throw('Expected no more than one @:inputs meta, found ${inputs.length}');
        }
    }
    
    static function getGroups(groups:Array<MetadataEntry>):Array<String>
    {
        final results = new Array<String>();
        for (group in groups)
        {
            switch group.params
            {
                case [_.expr => param]:
                    switch param
                    {
                        case EConst(CString(name, _)):
                            results.push(name);
                        case found:
                            throw 'Expected string arg on @:group meta, found: [${found.getName()}]';
                    }
                case found:
                    throw 'Expected string arg on @:group meta, found: ${found.map((p)->p.expr.getName())}';
            }
        }
        return results;
    }
    
    public function createGetter():Array<Field>
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
        final typeCt = switch [arg]
        {
            case ["value"]:
                (macro: flixel.addons.input.FlxAnalogSet.FlxAnalogSet1D<$actionCT>);
            case _:
                createAnalogSet1DType(arg, actionCT);
        }
        
        final getterName = 'get_$name';
        final fields = (macro class TempClass
        {
            public var $name(get, never):$typeCt;
            @:noCompletion
            inline function $getterName ()
            {
                return cast analogSets[$p{path}];
            }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    public function hasDefaults()
    {
        return inputs != null;
    }
    
    public function hasGroups()
    {
        return groups.length > 0;
    }
    
    static function createAnalogSet1DType(arg:String, actionCT:ComplexType)
    {
        final name = 'FlxAnalogSet1D__$arg';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({ pack: [], name: name });
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final getterName = 'get_$arg';
        
        // define the type
        final def = (macro class $name
        {
            /** The value of this action **/
            public var $arg(get, never):Float;
            inline function $getterName():Float { @:privateAccess return this.control.x; }
        });
        
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        
        final setType = (macro: flixel.addons.input.FlxAnalogSet.FlxAnalogSet1DBase<$actionCT>);
        def.kind = TDAbstract(setType, [setType], [setType]);
        
        Context.defineType(def);
        return TPath({ pack: [], name: name });
    }
    
    public function createAnalog2DField(argX:String, argY:String):Array<Field>
    {
        // get or create the joystick type
        final typeCt = switch [argX, argY]
        {
            case ["x", "y"]:
                (macro: flixel.addons.input.FlxAnalogSet.FlxAnalogSet2D<$actionCT>);
            case _:
                createAnalogSet2DType(argX, argY, actionCT);
        }
        
        final getterName = 'get_$name';
        final fields = (macro class TempClass
        {
            public var $name(get, never):$typeCt;
            @:noCompletion
            inline function $getterName ()
            {
                return cast analogSets[$p{path}];
            }
        }).fields;
        fields[0].doc = doc;
        
        return fields;
    }
    
    static function createAnalogSet2DType(argX:String, argY:String, actionCT:ComplexType)
    {
        final name = 'FlxAnalogSet2D__${argX}_${argY}';
        
        // Check whether the generated type already exists
        try
        {
            Context.getType(name);
            
            // Return a `ComplexType` for the generated type
            return TPath({ pack: [], name: name });
        }
        catch (e) {} // The generated type doesn't exist yet
        
        final getterX = 'get_$argX';
        final getterY = 'get_$argY';
        
        // define the type
        final def = (macro class $name
        {
            /** The horizontal component of this joystick **/
            public var $argX(get, never):Float;
            inline function $getterX():Float { @:privateAccess return this.control.x; }
            
            /** The vertical component of this joystick **/
            public var $argY(get, never):Float;
            inline function $getterY():Float { @:privateAccess return this.control.y; }
        });
        
        def.meta.push({ name:":forward", pos:Context.currentPos() });
        
        final setType = (macro: flixel.addons.input.FlxAnalogSet.FlxAnalogSet2DBase<$actionCT>);
        def.kind = TDAbstract(setType, [setType], [setType]);
        
        Context.defineType(def);
        return TPath({ pack: [], name: name });
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
    static var quotesArg = ~/(["'])(.+?)\1/;
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
                        ANALOG(parseMetaArg(arg, META));
                    case [argX, argY]:
                        ANALOG_XY(parseMetaArg(argX, META), parseMetaArg(argY, META));
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
    
    static function parseMetaArg(arg:Expr, metaName:String)
    {
        return switch(arg.expr)
        {
            case EConst(CString(name, _)):
                name;
            case EConst(CIdent(name)):
                name;
            case found:
                throw 'Invalid @$metaName arg, expected an identifier, found $found';
        }
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