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
				asserts.assert(command.optional == 'default');
				asserts.assert(command.result() == 'mandatory:$random,optional:default');
				return asserts.done();
			});
	}
	
	@:describe('Missing optional flags should be filled automatically (initialized)')
	public function initialized() {
		var command = new OptionalCommand();
		var random = StringTools.hex(Std.random(0xffff), 4).toLowerCase();
		
		return Cli.process(['--mandatory', random], command)
			.map(function(code) {
				asserts.assert(command.mandatory == random);
				asserts.assert(command.optional == 'default');
				asserts.assert(command.result() == 'mandatory:$random,optional:default');
				return asserts.done();
			});
	}
	
	@:describe('Missing optional flags should be filled automatically (meta)')
	public function meta() {
		var command = new MetaOptionalCommand();
		var random = StringTools.hex(Std.random(0xffff), 4).toLowerCase();
		
		return Cli.process(['--mandatory', random], command)
			.map(function(code) {
				asserts.assert(command.mandatory == random);
				asserts.assert(command.optional == null);
				asserts.assert(command.result() == 'mandatory:$random,optional:null');
				return asserts.done();
			});
	}
}

class OptionalCommand extends DebugCommand {
	
	public var mandatory:String;
	public var optional:String = 'default';
	
	@:defaultCommand
	public function run() {
		debug = 'mandatory:$mandatory,optional:$optional';
	}
}

class MetaOptionalCommand extends DebugCommand {
	
	public var mandatory:String;
	@:optional public var optional:String;
	
	@:defaultCommand
	public function run() {
		debug = 'mandatory:$mandatory,optional:${optional == null ? 'null' : optional}';
	}
}