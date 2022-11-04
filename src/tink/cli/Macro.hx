package tink.cli;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import tink.macro.TypeMap; // https://github.com/haxetink/tink_macro/pull/11

using Lambda;
using tink.MacroApi;
using tink.CoreApi;

class Macro {
	
	static var counter = 0;
	static var counters = new TypeMap<Int>();
	static var infoCache = new TypeMap<ClassInfo>();
	static var routerCache = new TypeMap<ComplexType>();
	static var docCache = new TypeMap<Expr>();
	static var TYPE_STRING = Context.getType('String');
	static var TYPE_STRINGLY = Context.getType('tink.Stringly');
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]):
				if(!routerCache.exists(type)) routerCache.set(type, buildClass(type));
				return routerCache.get(type);
			default: throw 'assert';
		}
	}
	
	public static function buildDoc(type:Type, pos) {
		
		if(!docCache.exists(type)) {
			
			var info = preprocess(type, pos);
			
			var commands = [];
			var flags = [];
			
			function s2e(v:String) return macro $v{v};
			function f2e(fields) return EObjectDecl(fields).at();
			
			for(command in info.commands) {
				commands.push([
					{field: 'isDefault', expr: macro $v{command.isDefault}},
					{field: 'isSub', expr: macro $v{command.isSub}},
					{field: 'names', expr: macro $a{command.names.map(s2e)}},
					{field: 'doc', expr: macro $v{getCommandDoc(command.field)}},
				]);
			}
			
			for(flag in info.flags) {
				flags.push([
					{field: 'names', expr: macro $a{flag.names.map(s2e)}},
					{field: 'aliases', expr: macro $a{flag.aliases.map(String.fromCharCode).map(s2e)}},
					{field: 'doc', expr: macro $v{flag.field.doc}},
				]);
			}
			
			var clsname = 'Doc' + getCounter(type);
			var def = macro class $clsname {
				
				static var doc:tink.cli.DocFormatter.DocSpec;
				
				public static function get() {
					if(doc == null)
						doc = ${
							EObjectDecl([
								{field: 'doc', expr: macro $v{info.cls.doc}},
								{field: 'commands', expr: macro $a{commands.map(f2e)}},
								{field: 'flags', expr: macro $a{flags.map(f2e)}},
							]).at()
						}
					return doc;
				}
			}
			
			def.pack = ['tink', 'cli'];
			
			Context.defineType(def);
			
			docCache.set(type, macro $p{['tink', 'cli', clsname]}.get());
			
		}
		
		return docCache.get(type);
	}
	
	static function buildClass(type:Type) {
		
		var info = preprocess(type, Context.currentPos());
		var cls = info.cls;
		
		// commands
		var defCommandCall = switch info.commands.find(function(c) return c.isDefault) {
			case null: Context.error('Default command not found, tag a function with @:defaultCommand', cls.pos);
			case cmd: buildCommandCall(cmd);
		}
		
		var cmdCases = [{
			values: [macro null],
			guard: null,
			expr: defCommandCall,
		}];
		var fields = [];
		for(command in info.commands) {
			if(!command.isDefault) cmdCases.push({
				values: [for(name in command.names) macro $v{name}],
				guard:null,
				expr: buildCommandCall(command),
			});
			fields.push(buildCommandField(command));
		}
		
		// flags
		var flagCases = [];
		var aliasCases = [];
		for(flag in info.flags) {
			var name = flag.field.name;
			var pos = flag.field.pos;
			var access = macro command.$name;
			
			function getAssignment(type:Type) {
				return switch type {
					case _.getID() => 'Bool':
						macro @:pos(pos) $access = true;
					case TInst(_.get() => {pack: [], name: 'Array'}, _):
						macro @:pos(pos) {
							if($access == null) $access = [];
							$access.push((args[++current]:tink.Stringly));
						}
					case TLazy(f):
						getAssignment(f());
					default:
						macro @:pos(pos) $access = (args[++current]:tink.Stringly);
				}
			}
				
			var assignment = getAssignment(flag.field.type);
			
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
		
		// prompt required flags
		var requiredFlags = info.flags.filter(function(f) return f.isRequired);
		requiredFlags.reverse(); // we build the prompt loop inside out
		var promptRequired = requiredFlags
			.fold(function(flag, prev) {
				var display = flag.names[0];
				var i = 0;
				while(display.charCodeAt(i) == '-'.code) i++;
				display = display.substr(i);
				
				var name = flag.field.name;
				var access = macro command.$name;
				
				return macro {
					var next =
						if($access == null)
							prompt.prompt($v{display})
								.next(function(v) {
									$access = v;
									return tink.core.Noise.Noise.Noise;
								});
						else
							tink.core.Future.sync(tink.core.Outcome.Success(tink.core.Noise.Noise.Noise));
							
					next.handle(function(o) switch o {
						case Success(_): $prev;
						case Failure(_): cb(o);
					});
				}
			}, macro cb(tink.core.Outcome.Success(tink.core.Noise.Noise.Noise)));
		
		// build the type
		var path = cls.module.split('.');
		if(path[path.length - 1] != cls.name) path.push(cls.name);
		var ct = TPath(path.join('.').asTypePath());
		var clsname = 'Router' + getCounter(type);
		var def = macro class $clsname extends tink.cli.Router<$ct> {
			
			public function new(command, prompt) {
				super(command, prompt, $v{info.flags.length > 0});
			}
			
			override function process(args:Array<String>):tink.cli.Result {
				return ${ESwitch(macro args[0], cmdCases, defCommandCall).at()}
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
			
			override function promptRequired():tink.core.Promise<tink.core.Noise> {
				return tink.core.Future.async(function(cb) $promptRequired);
			}
			
		}
		
		def.fields = def.fields.concat(fields);
		def.pack = ['tink', 'cli'];
		
		if(info.aliasDisabled) def.fields.remove(def.fields.find(function(f) return f.name == 'processAlias'));
		
		Context.defineType(def);
		
		return TPath('tink.cli.$clsname'.asTypePath());
	}
	
	static function preprocess(type:Type, pos:Position):ClassInfo {
		
		if(!infoCache.exists(type)) {
			
			var cls = switch type {
				case TInst(_.get() => cls, _): cls;
				default: pos.error('Expected a class instance but got ${type.getName()}');
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
				function addCommand(names:Array<String>, isDefault:Bool, isSub:Bool, skipFlags:SkipFlags) {
					for(command in info.commands) {
						for(n in names) if(command.names.indexOf(n) != -1)
							field.pos.makeFailure('Duplicate command: $n').sure();
					}
					info.commands.push({names: names, isDefault: isDefault, isSub: isSub, skipFlags: skipFlags, field: field});
				}
				
				function addFlag(names:Array<String>, aliases:Array<Int>, isRequired:Bool) {
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
						case [null, null]: info.flags.push({names: names, aliases: aliases, isRequired: isRequired, field: field});
						case [null, v]: field.pos.makeFailure('Duplicate flag alias: "-' + String.fromCharCode(v) + '". By default tink_cli uses the first letter of the flag Rename the alias with @:alias(<single-char>) or disable alias with @:alias(false).').sure();
						case [v, _]: field.pos.makeFailure('Duplicate flag name: $v').sure();
					}
				}
				
				// process commands
				
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
						for(p in params) 
                            if (p.getString().sure() == "")
                                commands.push(field.name);
                            else 
                                commands.push(p.getString().sure());
					case v:
						v[1].pos.makeFailure('Multiple @:command meta is not allowed').sure();
				}
				
				var skipFlags = switch field.meta.extract(':skipFlags') {
					case []:
						Nil;
					case [{params: []}]:
						All;
					case [{params: params, pos: pos}]:
						pos.makeFailure('@:skipFlags with arguments is not supported yet').sure();
						// Some([for(p in params) p.getString().sure()]);
					case v:
						v[1].pos.makeFailure('Multiple @:skipFlags meta is not allowed').sure();
				}
				
				if(commands.length > 0 || isDefault) {
					addCommand(commands, isDefault, field.kind.match(FVar(_)), skipFlags);
					continue;
				}
				
				// process flags
				
				switch field.kind {
					case FVar(_):
						var flags = [];
						
						// determine flag name
						switch field.meta.extract(':flag') {
							case []:
								flags.push('--' + field.name);
							case [{params: [macro false]}]:
								continue;
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
						
						// determine aliases
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
						
						// flag is marked as "required" (will be prompted when missing) if there is no default expr
						var isRequired = field.expr() == null && !field.meta.has(':optional');
						if(isRequired && !TYPE_STRINGLY.unifiesWith(field.type) && !TYPE_STRING.unifiesWith(field.type)) {
							var type = field.type.toComplex().toString();
							field.pos.error('$type is not supported. Please use a custom abstract to handle it. See https://github.com/haxetink/tink_cli#data-types');
						}
						
						addFlag(flags, aliases, isRequired);
					
					case FMethod(_):
				}
			}
			
			infoCache.set(type, info);
		}
		
		return infoCache.get(type);
	}
	
	static function buildCommandCall(command:Command) {
		var call = macro $i{'run_' + command.field.name};
		if(command.isSub) return macro $call(args.slice(1));
		
		var args = command.isDefault ? macro args : macro args.slice(1);
		
		return macro {
			var args = switch processArgs($args) {
				case Success(args): args;
				case Failure(f): return f;
			}
			${switch command.skipFlags {
				case Nil: macro promptRequired().next(function(_) return $call(args));
				case All: macro $call(args);
			}}
		}
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
									
									var breakpoint = restLocation;
									var remaining = args.length - restLocation - 1;
									if(promptLocation != -1) {
										if(restLocation > promptLocation)
											breakpoint -= 1;
										else 
											remaining -= 1;
									}
									
									for(i in 0...breakpoint) cargs.push(macro @:pos(pos) args[$v{i}]);
									
									cargs.push(macro @:pos(pos) args.slice($v{breakpoint}, args.length - $v{remaining}));
									
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
	
	static function getCounter(type:Type) {
		if(!counters.exists(type)) counters.set(type, counter++);
		return counters.get(type);
	}
	
	static function getCommandDoc(field:ClassField) {
		if(field.doc != null) return field.doc;
		switch(field.type) {
			case TInst(t, params): return t.get().doc;
			case _: return null;
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
	skipFlags:SkipFlags,
}

typedef Flag = {
	names:Array<String>,
	aliases:Array<Int>,
	isRequired:Bool,
	field:ClassField,
}

enum SkipFlags {
	Nil;
	// Some(v:Array<String>),
	All;
}
