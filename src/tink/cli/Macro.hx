package tink.cli;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using tink.MacroApi;
using tink.CoreApi;

class Macro {
	
	static var counter = 0;
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [TInst(_.get() => cls, _)]): return buildClass(cls);
			default: throw 'assert';
		}
	}
	
	static function buildClass(cls:ClassType) {
		
		var p = preprocess(cls);
		var commands = p.a;
		var flags = p.b;
		
		trace(flags.map(function(f) return f.name + ':' + String.fromCharCode(f.alias)));
		
		var path = cls.module.split('.');
		if(path[path.length - 1] != cls.name) path.push(cls.name);
		var ct = TPath(path.join('.').asTypePath());
		
		var cases = [];
		var fields = [];
		for(command in commands) {
			if(!command.isDefault) cases.push({
				values: [macro $v{command.name}],
				guard:null,
				expr: buildCommandCall(command),
			});
			fields.push(buildCommandField(command));
		}
		
		var defCommand = commands.find(function(c) return c.isDefault);
		if(defCommand == null) Context.error('Default command not found, tag a function with @:defaultCommand', cls.pos);
		
		var eSwitch = ESwitch(macro args[0], cases, buildCommandCall(defCommand)).at();
		
		var clsname = 'Router' + counter++;
		var def = macro class $clsname extends tink.cli.Router<$ct> {
			override function process(args:Array<String>) return $eSwitch;
		}
		
		def.fields = def.fields.concat(fields);
		def.pack = ['tink', 'cli'];
		Context.defineType(def);
		
		return Context.getType('tink.cli.$clsname');
	}
	
	static function preprocess(cls:ClassType) {
		var commands:Array<Command> = [];
		var flags:Array<Flag> = [];
		
		for(field in cls.fields.get()) if(field.isPublic) {
			
			function addCommand(name:String, isDefault = false) {
				switch commands.find(function(c) return c.name == name) {
					case null: commands.push({name: name, isDefault: isDefault, field: field});
					default: Context.error('Duplicate command: $name', field.pos);
				}
			}
			
			function addFlag(name:String, alias:Int) {
				switch [flags.find(function(f) return f.name == name), flags.find(function(f) return f.alias == alias)]  {
					case [null, null]: flags.push({name: name, alias: alias, field: field});
					case [null, v]: Context.error('Duplicate flag alias: ' + String.fromCharCode(v.alias), field.pos);
					case [v, _]: Context.error('Duplicate flag name: $name', field.pos);
				}
			}
			
			var command = null;
			var isDefault = false;
			
			switch field.meta.extract(':defaultCommand') {
				case [v]: command = field.name; isDefault = true;
				default:
			}
			
			switch field.meta.extract(':command') {
				case []: // not command
				case [{params: []}]: command = field.name;
				case [{params: [{expr: EConst(CString(v))}]}]: command = v;
				default: Context.error('Invalid @:command meta', field.pos);
			}
			
			if(command != null) {
				addCommand(command, isDefault);
				continue;
			}
			
			switch field.kind {
				case FVar(_):
					var flag = field.name;
					switch field.meta.extract(':flag') {
						case []: // do nothing
						case [{params: [{expr: EConst(CString(v))}]}]: flag = v;
						default: Context.error('Invalid @:flag meta', field.pos);
					}
					
					var alias = flag.charCodeAt(0);
					switch field.meta.extract(':alias') {
						case []: // do nothing
						case [{params: [{expr: EConst(CString(v))}]}] if(v.length == 1): alias = v.charCodeAt(0);
						default: Context.error('Invalid @:alias meta', field.pos);
					}
					
					addFlag(flag, alias);
				
				case FMethod(_):
			}
		}
		
		return new Pair(commands, flags);
	}
	
	static function buildCommandCall(command:Command) {
		var args = command.isDefault ? macro args : macro args.slice(1);
		return macro $i{'run_' + command.name}($args);
	}
	
	static function buildCommandField(command:Command):Field {
		return {
			access: [],
			name: 'run_' + command.name,
			kind: FFun({
				args: [{
					name: 'args',
					type: macro:Array<tink.Stringly>,
				}],
				ret: macro:tink.cli.ExitCode,
				expr: buildCommandForwardCall(command),
			}),
			pos: command.field.pos,
		}
	}
	
	static function buildCommandForwardCall(command:Command) {
		var name = command.field.name;
		return switch command.field.kind {
			case FVar(_):
				macro return tink.Cli.process(args, command.$name);
			case FMethod(_):
				function process(type:Type) {
					return switch type {
						case TLazy(f): process(f());
						case TFun(args, _):
							switch args {
								case []:
									macro return command.$name();
								case [{t: t}] if(Context.unify(t, (macro:Array<String>).toType().sure())):
									// TODO: allow putting at most one Array<String>/Rest<T> anywhere in the argument list
									macro return command.$name(args);
								default:
									var cargs = [for(i in 0...args.length) macro args[$v{i}]];
									macro return command.$name($a{cargs});
							}
						default: throw 'assert';
					}
				}
				process(command.field.type);
		}
	}
}

typedef Command = {
	name:String,
	isDefault:Bool,
	field:ClassField,
}

typedef Flag = {
	name:String,
	alias:Int,
	field:ClassField,
}