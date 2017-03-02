package;

import tink.cli.*;
import tink.Cli;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

class TestAliasDisabled {
	public function new() {}
	
	@:describe('Single Dash Flag')
	public function testSingleDash() {
		var command = new AliasCommand();
		return Cli.process(['-path', 'mypath', 'myarg'], command)
			.map(function(code) return equals('mypath', command.path) && equals('run myarg', command.result()));
	}
	
	@:describe('Alias Disabled')
	public function testAliasDisabled() {
		return Cli.process(['-p', 'mypath', 'myarg'], new AliasCommand())
			.and(Cli.process(['-n', 'myname', 'myarg'], new AliasCommand()))
			.map(function(result) return isFalse(result.a.isSuccess()) && isFalse(result.b.isSuccess()));
	}
	
}

class AliasCommand extends DebugCommand {
	
	public var name:String;
	
	@:flag('-path')
	public var path:String;
	
	@:defaultCommand
	public function run(args:Rest<String>) {
		debug = 'run ' + args.join(',');
	}
}
