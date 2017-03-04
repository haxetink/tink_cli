package tink.cli;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

using Lambda;
using tink.MacroApi;
using tink.CoreApi;

class Macro {
	
	static var counter = 0;
	static var infoCache = new tink.macro.TypeMap<ClassInfo>();
	static var cache = new tink.macro.TypeMap<Type>();
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]):
				if(!cache.exists(type)) cache.set(type, buildClass(type));
				return cache.get(type);
			default: throw 'assert';
		}
	}
	
	public static function buildDoc(type:Type) {
		
		var info = preprocess(type);
		
		var commands = [];
		var flags = [];
		
		function s2e(v:String) return macro $v{v};
		function f2e(fields) return EObjectDecl(fields).at();
		
		for(command in info.commands) {
			commands.push([
				{field: 'isDefault', expr: macro $v{command.isDefault}},
				{field: 'isSub', expr: macro $v{command.isSub}},
				{field: 'names', expr: macro $a{command.names.map(s2e)}},
				{field: 'doc', expr: macro $v{command.field.doc}},
			]);
		}
		
		for(flag in info.flags) {
			flags.push([
				{field: 'names', expr: macro $a{flag.names.map(s2e)}},
				{field: 'aliases', expr: macro $a{flag.aliases.map(String.fromCharCode).map(s2e)}},
				{field: 'doc', expr: macro $v{flag.field.doc}},
			]);
		}
		
		return EObjectDecl([
			{field: 'doc', expr: macro $v{info.cls.doc}},
			{field: 'commands', expr: macro $a{commands.map(f2e)}},
			{field: 'flags', expr: macro $a{flags.map(f2e)}},
		]).at();
	}
	
	static function buildClass(type:Type) {
		
		var info = preprocess(type);
		var cls = info.cls;
		
		// commands
		var cmdCases = [];
		var fields = [];
		for(command in info.commands) {
			if(!command.isDefault) cmdCases.push({
				values: [for(name in command.names) macro $v{name}],
				guard:null,
				expr: buildCommandCall(command),
			});
			fields.push(buildCommandField(command));
		}
		
		var defCommand = info.commands.find(function(c) return c.isDefault);
		if(defCommand == null) Context.error('Default command not found, tag a function with @:defaultCommand', cls.pos);
		
		// flags
		var flagCases = [];
		var aliasCases = [];
		for(flag in info.flags) {
			var name = flag.field.name;
			var pos = flag.field.pos;
			var access = macro command.$name;
			
			var assignment = switch flag.field.type {
				case _.getID() => 'Bool':
					macro @:pos(pos) $access = true;
				case TInst(_.get() => {pack: [], name: 'Array'}, _):
					macro @:pos(pos) {
						if($access == null) $access = [];
						$access.push((args[++current]:tink.Stringly));
					}
				default:
					macro @:pos(pos) $access = (args[++current]:tink.Stringly);
			}
			
			if(flag.names.length > 0) flagCases.push({
				values: [for(name in flag.names) macro @:pos(pos) $v{name}],
				guard: null,
				expr: assignment,
			});
			
			if(flag.aliases.length > 0) aliasCases.push({
				values: [for(alias in flag.aliases) macro @:pos(pos) $v{alias}],
				guard: null,
				expr: assignment,
			});
		}
		
		// build the type
		var path = cls.module.split('.');
		if(path[path.length - 1] != cls.name) path.push(cls.name);
		var ct = TPath(path.join('.').asTypePath());
		var clsname = 'Router' + counter++;
		var def = macro class $clsname extends tink.cli.Router<$ct> {
			
			override function process(args:Array<String>):tink.cli.Result return {
				${ESwitch(macro args[0], cmdCases, buildCommandCall(defCommand)).at()}
			}
			
			override function processFlag(args:Array<String>, index:Int) {
				var current = index;
				${ESwitch(macro args[index], flagCases, macro return -1).at()}
				return current - index;
			}
			
			override function processAlias(args:Array<String>, index:Int) {
				var current = index;
				var str = args[index];
				for(i in 1...str.length)
					${ESwitch(macro str.charCodeAt(i), aliasCases, macro throw "Invalid alias '-" + str.charAt(i) + "'").at()}
					
				return current - index;
			}
			
		}
		
		def.fields = def.fields.concat(fields);
		def.pack = ['tink', 'cli'];
		
		if(info.aliasDisabled) def.fields.remove(def.fields.find(function(f) return f.name == 'processAlias'));
		
		Context.defineType(def);
		
		return Context.getType('tink.cli.$clsname');
	}
	
	static function preprocess(type:Type):ClassInfo {
		
		if(!infoCache.exists(type)) {
			
			var cls = switch type {
				case TInst(_.get() => cls, _): cls;
				default: throw 'assert';
			}
			
			var info:ClassInfo = {
				aliasDisabled: switch cls.meta.extract(':alias') {
					case [{params: [macro false]}]: true;
					default: false;
				},
				flags: [],
				commands: [],
				cls: cls,
			}
			
			for(field in cls.fields.get()) if(field.isPublic) {
				function addCommand(names:Array<String>, isDefault:Bool, isSub:Bool) {
					for(command in info.commands) {
						for(n in names) if(command.names.indexOf(n) != -1)
							field.pos.makeFailure('Duplicate command: $n').sure();
					}
					info.commands.push({names: names, isDefault: isDefault, isSub: isSub, field: field});
				}
				
				function addFlag(names:Array<String>, aliases:Array<Int>) {
					field.meta.remove(':flag');
					field.meta.remove(':alias');
					var usedName = null;
					var usedAlias = null;
					for(flag in info.flags) {
						for(n in names) if(flag.names.indexOf(n) != -1) {
							usedName = n;
							break;
						}
						
						if(!info.aliasDisabled) for(a in aliases) if(flag.aliases.indexOf(a) != -1) {
							usedAlias = a;
							break;
						}
					}
					switch [usedName, usedAlias]  {
						case [null, null]: info.flags.push({names: names, aliases: aliases, field: field});
						case [null, v]: field.pos.makeFailure('Duplicate flag alias: "-' + String.fromCharCode(v) + '"').sure();
						case [v, _]: field.pos.makeFailure('Duplicate flag name: $v').sure();
					}
				}
				
				var commands = [];
				var isDefault = false;
				
				switch field.meta.extract(':defaultCommand') {
					case [v]: isDefault = true;
					default:
				}
				
				switch field.meta.extract(':command') {
					case []: // not command
					case [{params: []}]:
						commands.push(field.name);
					case [{params: params}]:
						for(p in params) commands.push(p.getString().sure());
					case v:
						v[1].pos.makeFailure('Invalid @:command meta');
				}
				
				if(commands.length > 0 || isDefault) {
					addCommand(commands, isDefault, field.kind.match(FVar(_)));
					continue;
				}
				
				switch field.kind {
					case FVar(_):
						var flags = [];
						switch field.meta.extract(':flag') {
							case []:
								flags.push('--' + field.name);
							case [{params: params}]:
								for(p in params) {
									var flag = p.getString().sure();
									switch [flag.charCodeAt(0), flag.charCodeAt(1)] {
										case ['-'.code, '-'.code]: flags.push(flag);
										case ['-'.code, _]: flags.push(flag); info.aliasDisabled = true;
										default: flags.push('--$flag');
									}
								}
							case v:
								v[1].pos.makeFailure('Only a single @:flag meta is allowed').sure();
						}
						
						var aliases = [];
						switch field.meta.extract(':alias') {
							case []:
								for(flag in flags)
									for(i in 0...flag.length)
										switch flag.charCodeAt(i) {
											case '-'.code: // continue
											case v:
												if(aliases.indexOf(v) == -1) aliases.push(v);
												break;
										}
							case [{params: params}]:
								for(p in params) {
									switch p.getIdent() {
										case Success('false'):
											aliases = [];
											break;
										default: 
											var v = p.getString().sure();
											if(v.length == 1) aliases.push(v.charCodeAt(0));
											else p.pos.makeFailure('Alias must be a single letter').sure();
									}
								}
							case v:
								v[1].pos.makeFailure('Only a single @:alias meta is allowed').sure();
						}
						addFlag(flags, aliases);
					
					case FMethod(_):
				}
			}
			
			infoCache.set(type, info);
		}
		
		return infoCache.get(type);
	}
	
	static function buildCommandCall(command:Command) {
		var args = command.isDefault ? macro args : macro args.slice(1);
		if(!command.isSub) {
			args = macro switch processArgs($args) {
				case Success(args): args;
				case Failure(f): return tink.core.Outcome.Failure(f);
			}
		}
		return macro $i{'run_' + command.field.name}($args);
	}
	
	static function buildCommandField(command:Command):Field {
		return {
			access: [],
			name: 'run_' + command.field.name,
			kind: FFun({
				args: [{
					name: 'args',
					type: macro:Array<tink.Stringly>,
				}],
				ret: macro:tink.cli.Result,
				expr: buildCommandForwardCall(command),
			}),
			pos: command.field.pos,
		}
	}
	
	static function buildCommandForwardCall(command:Command) {
		var name = command.field.name;
		var pos = command.field.pos;
		return if(command.isSub) {
			macro return tink.Cli.process(args, command.$name);
		} else {
			function process(type:Type) {
				return switch type {
					case TLazy(f): process(f());
					case TFun(args, ret):
						var expr = switch args {
							case []:
								macro command.$name();
							default:
								var requiredParams = args.length;
								var restLocation = -1;
								var promptLocation = -1;
								
								for(i in 0...args.length) {
									var arg = args[i];
									switch arg.t.reduce() {
										case TAbstract(_.get() => {pack: ['tink', 'cli'], name: 'Rest'}, _):
											if(restLocation != -1) command.field.pos.makeFailure('A command can only accept at most one Rest<T> argument').sure();
											requiredParams--;
											restLocation = i;
											
										case _.getID() => 'tink.cli.Prompt':
											if(promptLocation != -1)  command.field.pos.makeFailure('A command can only accept at most one "prompt" argument').sure();
											requiredParams--;
											promptLocation = i;
									
										default:
											
									}
								}
								
								
								var cargs = [];
								var cargsNum = args.length;
								if(promptLocation != -1) cargsNum--;
								
								var expr = macro @:pos(pos) if(args.length < $v{requiredParams}) return tink.core.Outcome.Failure(new tink.core.Error('Insufficient arguments. Expected: ' + $v{requiredParams} + ', Got: ' + args.length));
								
								if(restLocation == -1) {
									
									for(i in 0...cargsNum) cargs.push(macro @:pos(pos) args[$v{i}]);
									
								} else {
									
									for(i in 0...restLocation) cargs.push(macro @:pos(pos) args[$v{i}]);
									
									var remaining = cargsNum - restLocation - 1;
									cargs.push(macro @:pos(pos) args.slice($v{restLocation}, args.length - $v{remaining}));
									
									for(i in 0...remaining) cargs.push(macro @:pos(pos) args[args.length - $v{remaining - i}]);
									
								}
								
								if(promptLocation != -1) cargs.insert(promptLocation, macro prompt);
								
								expr = expr.concat(macro command.$name($a{cargs}));
						}
						
						var ret = switch ret.reduce() {
							case TAbstract(_.get() => {pack: ['tink', 'core'], name: 'Promise'}, [t])
							| TAbstract(_.get() => {pack: ['tink', 'core'], name: 'Future'}, [TEnum(_.get() => {pack: ['tink', 'core'], name: 'Outcome'}, [t, _])])
							| TEnum(_.get() => {pack: ['tink', 'core'], name: 'Outcome'}, [t, _])
							| TAbstract(_.get() => {pack: ['tink', 'core'], name: 'Future'}, [t]): t;
							case t: t;
						}
						
						switch ret {
							case v if(v.getID() == 'Void'):
								expr = expr.concat(macro tink.core.Noise.Noise.Noise);
							case v if(v.getID() == 'tink.core.Noise'):
									// ok
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

typedef ClassInfo = {
	commands:Array<Command>,
	flags:Array<Flag>,
	aliasDisabled:Bool,
	cls:ClassType,
}

typedef Command = {
	names:Array<String>,
	isDefault:Bool,
	isSub:Bool,
	field:ClassField,
}

typedef Flag = {
	names:Array<String>,
	aliases:Array<Int>,
	field:ClassField,
}