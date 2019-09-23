package;

import tink.cli.*;
import tink.Cli;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

@:asserts
class TestFlag {
	public function new() {}
	
	@:variant('Flag' (['--name', 'myname', 'myarg'], 'myname', 'run myarg'))
	@:variant('Alias' (['-n', 'myname', 'myarg'], 'myname', 'run myarg'))
	@:variant('Argument before Flag' (['myarg', '--name', 'myname'], 'myname', 'run myarg'))
	@:variant('Argument before Alias' (['myarg', '-n', 'myname'], 'myname', 'run myarg'))
	@:variant('Assignment' (['myarg', '--name=myname'], 'myname', 'run myarg'))
	@:variant('Double Dashes end Flags' (['--name=myname', '--', '--myarg=foo'], 'myname', 'run --myarg=foo'))
	public function flags(args:Array<String>, name:String, result:String) {
		var command = new FlagCommand();
		return Cli.process(args, command)
			.map(function(code) {
				asserts.assert(name == command.name);
				asserts.assert(result == command.result());
				return asserts.done();
			});
	}
	
	@:variant('Renamed' (['--another-name', 'mypath', 'myarg'], 'mypath', 'run myarg'))
	@:variant('Renamed Alias' (['-a', 'mypath', 'myarg'], 'mypath', 'run myarg'))
	public function renamed(args:Array<String>, path:String, result:String) {
		var command = new FlagCommand();
		return Cli.process(args, command)
			.map(function(code) {
				asserts.assert(path == command.path);
				asserts.assert(result == command.result());
				return asserts.done();
			});
	}
	
	
	@:describe('Combined Alias')
	@:variant(['-an', 'mypath', 'myname', 'myarg'], 'mypath', 'myname', 'run myarg')
	@:variant(['-na', 'myname', 'mypath', 'myarg'], 'mypath', 'myname', 'run myarg')
	public function testCombinedAlias(args, path, name, result) {
		var command = new FlagCommand();
		return Cli.process(args, command)
			.map(function(_) {
				asserts.assert(path == command.path);
				asserts.assert(name == command.name);
				asserts.assert(result == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Bool Flag')
	public function testBool() {
		var command = new FlagCommand();
		return Cli.process(['--force', 'myarg'], command)
			.map(function(code) {
				asserts.assert(command.force);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Int Flag')
	public function testInt() {
		var command = new FlagCommand();
		return Cli.process(['--int', '123','myarg'], command)
			.map(function(code) {
				asserts.assert(123 == command.int);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Float Flag')
	public function testFloat() {
		var command = new FlagCommand();
		return Cli.process(['--float', '1.23', 'myarg'], command)
			.map(function(code) {
				asserts.assert(1.23 == command.float);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Int Array Flag')
	public function testInts() {
		var command = new FlagCommand();
		return Cli.process(['--ints', '123', '--ints', '234', '--ints', '456', 'myarg'], command)
			.map(function(code) {
				asserts.assert('[123,234,456]' == haxe.Json.stringify(command.ints));
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Float Array Flag')
	public function testFloats() {
		var command = new FlagCommand();
		return Cli.process(['--floats', '1.23', '--floats', '2.34', '--floats', '3.45', 'myarg'], command)
			.map(function(code) {
				asserts.assert('[1.23,2.34,3.45]' == haxe.Json.stringify(command.floats));
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('String Array Flag')
	public function testStrings() {
		var command = new FlagCommand();
		return Cli.process(['--strings', 'a', '--strings', 'b', '--strings', 'c', 'myarg'], command)
			.map(function(code) {
				asserts.assert('["a","b","c"]' == haxe.Json.stringify(command.strings));
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Custom Map')
	public function testCustomMap() {
		var command = new FlagCommand();
		return Cli.process(['--map', 'a=1,b=2,c=3', 'myarg'], command)
			.map(function(code) {
				asserts.assert('a=>1,b=>2,c=>3' == command.map.toString());
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Multiple Flag Names')
	@:variant('--multi1')
	@:variant('--multi2')
	@:variant('-m')
	public function testMultipleFlagNames(cmd) {
		var command = new FlagCommand();
		return Cli.process([cmd, 'multi', 'myarg'], command)
			.map(function(_) {
				asserts.assert('multi' == command.multi);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Multiple Aliases')
	@:variant('-x')
	@:variant('-y')
	@:variant('-z')
	public function testMultipleAliases(flag) {
		var command = new FlagCommand();
		return Cli.process([flag, 'multi', 'myarg'], command)
			.map(function(_) {
				asserts.assert('multi' == command.multiAlias);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	
	
	@:describe('No Alias')
	public function testNoAlias() {
		var command = new FlagCommand();
		return Cli.process(['-w', 'multi', 'myarg'], command)
			.map(function(result) return assert(!result.isSuccess()));
	}
}

class FlagCommand extends DebugCommand {
	
	public var name:String = null;
	
	@:flag('another-name')
	public var path:String = null;
	
	@:flag('multi1', 'multi2')
	public var multi:String = null;
	
	@:alias('x', 'y', 'z')
	public var multiAlias:String = null;
	
	@:alias('b')
	public var force:Bool = false;
	
	public var int:Int = 0;
	public var float:Float = 0;
	
	@:flag(false)
	public var notFlag:String;
	
	@:alias('j')
	public var ints:Array<Int> = null;
	@:alias('k')
	public var floats:Array<Float> = null;
	public var strings:Array<String> = null;
	
	// public var rstrings:Array<String>;
	
	@:alias('o')
	public var map:CustomMap = null;

	@:alias(false)
	public var withoutalias:String = null;
	
	@:defaultCommand
	public function run(args:Rest<String>) {
		debug = 'run ' + args.join(',');
	}
}

@:forward
abstract CustomMap(StringMap<Int>) from StringMap<Int> to StringMap<Int> {
	@:from
	public static function fromString(v:String):CustomMap {
		var map = new StringMap<Int>();
		for(i in v.split(',')) switch i.split('=') {
			case [key, value]: map.set(key, (value:tink.Stringly));
			default: throw 'Invalid format';
		}
		return map;
	}
	
	public function toString() {
		var keys = [for(key in this.keys()) key];
		keys.sort(Reflect.compare);
		return [for(key in keys) '$key=>' + this.get(key)].join(',');
	}
} 