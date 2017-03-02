package;

import tink.Cli;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

class TestFlag {
	public function new() {}
	
	@:describe('Flag')
	public function testFlag() {
		var command = new FlagCommand();
		return Cli.process(['--name', 'myname', 'myarg'], command)
			.map(function(code) return equals('myname', command.name) && equals('run myarg', command.result()));
	}
	
	@:describe('Alias')
	public function testAlias() {
		var command = new FlagCommand();
		return Cli.process(['-n', 'myname', 'myarg'], command)
			.map(function(code) return equals('myname', command.name) && equals('run myarg', command.result()));
	}
	
	
	@:describe('Argument before Flag')
	public function testArgB4Flag() {
		var command = new FlagCommand();
		return Cli.process(['myarg', '--name', 'myname'], command)
			.map(function(code) return equals('myname', command.name) && equals('run myarg', command.result()));
	}
	
	@:describe('Argument before Alias')
	public function testArgB4Alias() {
		var command = new FlagCommand();
		return Cli.process(['myarg', '-n', 'myname'], command)
			.map(function(code) return equals('myname', command.name) && equals('run myarg', command.result()));
	}
	
	
	@:describe('Renamed')
	public function testRenamed() {
		var command = new FlagCommand();
		return Cli.process(['--another-name', 'mypath', 'myarg'], command)
			.map(function(code) return equals('mypath', command.path) && equals('run myarg', command.result()));
	}
	
	@:describe('Renamed Alias')
	public function testRenamedAlias() {
		var command = new FlagCommand();
		return Cli.process(['-a', 'mypath', 'myarg'], command)
			.map(function(code) return equals('mypath', command.path) && equals('run myarg', command.result()));
	}
	
	
	@:describe('Combined Alias')
	public function testCombinedAlias() {
		
		var result = isTrue(true);
		var command = new FlagCommand();
		var run1 = Cli.process(['-an', 'mypath', 'myname', 'myarg'], command);
		run1.handle(function(_)
			result = result && 
				equals('mypath', command.path) && 
				equals('myname', command.name) &&
				equals('run myarg', command.result())
		);
		var command = new FlagCommand();
		var run2 = Cli.process(['-na', 'myname', 'mypath', 'myarg'], command);
		run2.handle(function(_)
			result = result && 
				equals('mypath', command.path) && 
				equals('myname', command.name) &&
				equals('run myarg', command.result())
		);
		return Future.ofMany([run1, run2]).map(function(_) return result);
	}
	
	@:describe('Bool Flag')
	public function testBool() {
		var command = new FlagCommand();
		return Cli.process(['--force', 'myarg'], command)
			.map(function(code) return isTrue(command.force) && equals('run myarg', command.result()));
	}
	
	@:describe('Int Flag')
	public function testInt() {
		var command = new FlagCommand();
		return Cli.process(['--int', '123','myarg'], command)
			.map(function(code) return equals(123, command.int) && equals('run myarg', command.result()));
	}
	
	@:describe('Float Flag')
	public function testFloat() {
		var command = new FlagCommand();
		return Cli.process(['--float', '1.23', 'myarg'], command)
			.map(function(code) return equals(1.23, command.float) && equals('run myarg', command.result()));
	}
	
	@:describe('Int Array Flag')
	public function testInts() {
		var command = new FlagCommand();
		return Cli.process(['--ints', '123', '--ints', '234', '--ints', '456', 'myarg'], command)
			.map(function(code) return equals('[123,234,456]', haxe.Json.stringify(command.ints)) && equals('run myarg', command.result()));
	}
	
	@:describe('Float Array Flag')
	public function testFloats() {
		var command = new FlagCommand();
		return Cli.process(['--floats', '1.23', '--floats', '2.34', '--floats', '3.45', 'myarg'], command)
			.map(function(code) return equals('[1.23,2.34,3.45]', haxe.Json.stringify(command.floats)) && equals('run myarg', command.result()));
	}
	
	@:describe('String Array Flag')
	public function testStrings() {
		var command = new FlagCommand();
		return Cli.process(['--strings', 'a', '--strings', 'b', '--strings', 'c', 'myarg'], command)
			.map(function(code) return equals('["a","b","c"]', haxe.Json.stringify(command.strings)) && equals('run myarg', command.result()));
	}
	
	@:describe('Custom Map')
	public function testCustomMap() {
		var command = new FlagCommand();
		return Cli.process(['--map', 'a=1,b=2,c=3', 'myarg'], command)
			.map(function(code) return equals('a=>1,b=>2,c=>3', command.map.toString()) && equals('run myarg', command.result()));
	}
	
	@:describe('Multiple Flag Names')
	public function testMultipleFlagNames() {
		var result = isTrue(true);
		
		function run(i) {
			var command = new FlagCommand();
			var run1 = Cli.process([i, 'multi', 'myarg'], command);
			run1.handle(function(_)
				result = result && 
					equals('multi', command.multi) && 
					equals('run myarg', command.result())
			);
			return run1;
		}
		
		return Future.ofMany([
			run('--multi1'),
			run('--multi2'),
			run('-m'),
		]).map(function(_) return result);
	}
	
	@:describe('Multiple Aliases')
	public function testMultipleAliases() {
		var result = isTrue(true);
		
		function run(i) {
			var command = new FlagCommand();
			var run1 = Cli.process([i, 'multi', 'myarg'], command);
			run1.handle(function(_)
				result = result && 
					equals('multi', command.multiAlias) && 
					equals('run myarg', command.result())
			);
			return run1;
		}
		
		return Future.ofMany([
			run('-x'),
			run('-y'),
			run('-z'),
		]).map(function(_) return result);
	}
}

class FlagCommand extends DebugCommand {
	
	public var name:String;
	
	@:flag('another-name')
	public var path:String;
	
	@:flag('multi1', 'multi2')
	public var multi:String;
	
	@:alias('x', 'y', 'z')
	public var multiAlias:String;
	
	@:alias('b')
	public var force:Bool;
	
	public var int:Int;
	public var float:Float;
	
	@:alias('j')
	public var ints:Array<Int>;
	@:alias('k')
	public var floats:Array<Float>;
	public var strings:Array<String>;
	
	@:alias('o')
	public var map:CustomMap;
	
	@:defaultCommand
	public function run(args:Array<String>) {
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
		return [for(key in this.keys()) '$key=>' + this.get(key)].join(',');
	}
} 