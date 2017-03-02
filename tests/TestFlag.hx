package;

import tink.Cli;
import tink.unit.Assert.*;

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
		
		var result = isTrue(true);
		var command = new FlagCommand();
		var run1 = Cli.process(['-b', 'myarg'], command);
		run1.handle(function(_)
			result = result && 
				isTrue(command.force) &&
				equals('run myarg', command.result())
		);
		var command = new FlagCommand();
		var run2 = Cli.process(['--force', 'myarg'], command);
		run2.handle(function(_)
			result = result && 
				isTrue(command.force) &&
				equals('run myarg', command.result())
		);
		return Future.ofMany([run1, run2]).map(function(_) return result);
	}
}

class FlagCommand extends DebugCommand {
	
	public var name:String;
	
	@:flag('another-name')
	public var path:String;
	
	@:alias('b')
	public var force:Bool;
	
	@:defaultCommand
	public function run(args:Array<String>) {
		debug = 'run ' + args.join(',');
	}
}