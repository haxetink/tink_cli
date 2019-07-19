package;

import tink.cli.*;
import tink.Cli;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

@:asserts
class TestAliasDisabled {
	public function new() {}
	
	@:describe('Single Dash Flag')
	public function testSingleDash() {
		var command = new AliasCommand();
		return Cli.process(['-path', 'mypath', 'myarg'], command)
			.map(function(code) {
				asserts.assert('mypath' == command.path);
				asserts.assert('run myarg' == command.result());
				return asserts.done();
			});
	}
	
	@:describe('Alias Disabled')
	public function testAliasDisabled() {
		return Cli.process(['-p', 'mypath', 'myarg'], new AliasCommand())
			.and(Cli.process(['-n', 'myname', 'myarg'], new AliasCommand()))
			.map(function(result) {
				asserts.assert(!result.a.isSuccess());
				asserts.assert(!result.b.isSuccess());
				return asserts.done();
			});
	}
	
}

class AliasCommand extends DebugCommand {
	
	public var name:String = null;
	
	@:flag('-path')
	public var path:String = null;
	
	@:defaultCommand
	public function run(args:Rest<String>) {
		debug = 'run ' + args.join(',');
	}
}
