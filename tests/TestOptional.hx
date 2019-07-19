package;

import tink.Cli;
import tink.cli.*;
import tink.cli.prompt.*;
import tink.io.Sink;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

@:asserts
class TestOptional {
	public function new() {}
	
	@:describe('Missing mandatory flags should trigger prompt')
	public function mandatory() {
		var command = new OptionalCommand();
		var random = StringTools.hex(Std.random(0xffff), 4).toLowerCase();
		
		return Cli.process([], command, new IoPrompt('$random\n', Sink.BLACKHOLE))
			.map(function(code) {
				asserts.assert(command.mandatory == random);
				asserts.assert(command.optional == 'opt');
				asserts.assert(command.result() == 'mandatory:$random,optional:opt');
				return asserts.done();
			});
	}
	
	@:describe('Missing optional flags should be filled automatically')
	public function optional() {
		var command = new OptionalCommand();
		var random = StringTools.hex(Std.random(0xffff), 4).toLowerCase();
		
		return Cli.process(['--mandatory', random], command)
			.map(function(code) {
				asserts.assert(command.mandatory == random);
				asserts.assert(command.optional == 'opt');
				asserts.assert(command.result() == 'mandatory:$random,optional:opt');
				return asserts.done();
			});
	}
}

class OptionalCommand extends DebugCommand {
	
	public var mandatory:String;
	public var optional:String = 'opt';
	
	@:defaultCommand
	public function run() {
		debug = 'mandatory:$mandatory,optional:$optional';
	}
}