package flixel.addons.system.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using haxe.macro.TypeTools;

class FlxControlsMacro
{
    static public function buildControlList(type:ClassType, param:BaseType):ComplexType
    {
        // generate new type extending the given type
        final typeName = '${type.name}';
        final name = '${typeName}_${param.name}';
        final complexType = Context.getType(param.name).toComplexType();
        
        // generate new type
        final newType = macro class $name extends flixel.addons.input.FlxControlListBase<$complexType>
            {
                public function new() { super(); }
            };
        
        newType.pos = Context.currentPos();
        
        Context.defineType(newType, type.module);
        
        return TPath({pack: [], name: name});
    }
    
    static public function generateControlFields():ComplexType
    {
        trace('local: ${Context.getLocalType()}');
        switch (Context.getLocalType())
        {
            case TInst(type, [TEnum(param, [])]):
                trace('enum param: $param');
                return buildControlList(type.get(), param.get());
            case TInst(type, [TInst(param, [])]):
                trace('inst param: $param');
                return buildControlList(type.get(), param.get());
            case TInst(type, [found]):
                return buildControlList(type.get(), param.get());
                throw 'Expecting EnumValue type param, found $found';
            case TInst(type, _):
                throw 'Expecting single EnumValue type param, found multiple';
            case _:
                throw "D'oh!";
        }
    }
    
    
    static public function buildSpecial()
    {
        switch (Context.getLocalType())
        {
            case TInst(type, [t1]):
                switch t1.follow()
                {
                    case TEnum(param, []):
                        trace(' enum: $param');
                        final paramName = param.get().name;
                        final paramType = Context.getType(paramName);
                        return buildType(type.get(), paramName, paramType);
                        case TAnonymous(_.get() => t):
                            trace(t);
                            // trace(t1);
                            
                            throw "D'oh!";
                        case TInst(type, []):
                            trace(type.follow());
                        }
                        case _:
                    trace(Context.getLocalType());
                            throw "D'oh!";
                }
        }
}