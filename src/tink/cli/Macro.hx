package tink.cli;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using tink.MacroApi;
using tink.CoreApi;

class Macro {
	
	static var counter = 0;
	static var cache = new tink.macro.TypeMap<Type>();
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]):
				if(!cache.exists(type)) {
					cache.set(type, buildClass(switch type {
						case TInst(_.get() => cls, _): cls;
						default: throw 'assert';
					}));
				}
				return cache.get(type);
			default: throw 'assert';
		}
	}
	
	static function buildClass(cls:ClassType) {
		var p = preprocess(cls);
		var commands = p.a;
		var flags = p.b;
		
		// commands
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
		
		var commandProcessor = ESwitch(macro args[0], cases, buildCommandCall(defCommand)).at();
		
		// flags
		var flagCases = [];
		var aliasCases = [];
		for(flag in flags) {
			var name = flag.field.name;
			var assignment = switch flag.field.type.getID() {
				case 'Bool': macro command.$name = true;
				default: macro command.$name = args[++current];
			}
			flagCases.push({
				values: [for(name in flag.names) macro $v{'--$name'}],
				guard: null,
				expr: assignment,
			});
			aliasCases.push({
				values: [for(alias in flag.aliases) macro $v{alias}],
				guard: null,
				expr: assignment,
			});
		}
		
		var flagProcessor = macro {
			var current = index;
			${ESwitch(macro args[index], flagCases, macro throw "Invalid flag '" + args[index] + "'").at()}
			return current - index;
		}
		
		var aliasProcessor = macro {
			var current = index;
			var str = args[index];
			for(i in 1...str.length) {
				${ESwitch(macro str.charCodeAt(i), aliasCases, macro throw "Invalid alias '-" + str.charAt(i) + "'").at()}
			}
			return current - index;
		}
		
		// build the type
		var path = cls.module.split('.');
		if(path[path.length - 1] != cls.name) path.push(cls.name);
		var ct = TPath(path.join('.').asTypePath());
		var clsname = 'Router' + counter++;
		var def = macro class $clsname extends tink.cli.Router<$ct> {
			override function process(args:Array<String>) return $commandProcessor;
			override function processFlag(args:Array<String>, index:Int) $flagProcessor;
			override function processAlias(args:Array<String>, index:Int) $aliasProcessor;
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
			
			function addFlag(names:Array<String>, aliases:Array<Int>) {
				var usedName = null;
				var usedAlias = null;
				for(flag in flags) {
					for(n in names) if(flag.names.indexOf(n) != -1) {
						usedName = n;
						break;
					}
					for(a in aliases) if(flag.aliases.indexOf(a) != -1) {
						usedAlias = null;
						break;
					}
				}
				switch [usedName, usedAlias]  {
					case [null, null]: flags.push({names: names, aliases: aliases, field: field});
					case [null, v]: Context.error('Duplicate flag alias: ' + String.fromCharCode(v), field.pos);
					case [v, _]: Context.error('Duplicate flag name: $v', field.pos);
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
					
					addFlag([flag], [alias]);
				
				case FMethod(_):
			}
		}
		
		return new Pair(commands, flags);
	}
	
	static function buildCommandCall(command:Command) {
		var args = command.isDefault ? macro args : macro args.slice(1);
		return macro $i{'run_' + command.name}(processArgs($args));
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
						case TFun(args, ret):
							var expr = switch args {
								case []:
									macro command.$name();
								case [{t: t}] if(Context.unify(t, (macro:Array<String>).toType().sure())):
									// TODO: allow putting at most one Array<String>/Rest<T> anywhere in the argument list
									macro command.$name(args);
								default:
									var cargs = [for(i in 0...args.length) macro args[$v{i}]];
									macro command.$name($a{cargs});
							}
							
							var ret = switch ret.reduce() {
								case TAbstract(_.get() => {name: 'Future'}, [TEnum(_.get() => {name: 'Outcome'}, [t, _])])
								| TEnum(_.get() => {name: 'Outcome'}, [t, _])
								| TAbstract(_.get() => {name: 'Future'}, [t]): t;
								case t: t;
							}
							
							switch ret {
								case v if(v.getID() == 'Void'):
									expr = expr.concat(macro tink.core.Noise.Noise.Noise);
								case v if(v.getID() == 'tink.core.Noise'): // ok
								case TAnonymous(_): 
									var ct = ret.toComplex();
									expr = macro ($expr:tink.core.Promise<$ct>);
								case _.getID() => id:
									var ct = id == null ? macro:tink.core.Noise : ret.toComplex();
									expr = macro ($expr:tink.core.Promise<$ct>);
							}
							macro return $expr;
							
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
	names:Array<String>,
	aliases:Array<Int>,
	field:ClassField,
}