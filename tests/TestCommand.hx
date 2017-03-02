package;

import tink.Cli;
import tink.unit.Assert.*;

using tink.CoreApi;

class TestCommand {
	public function new() {}
	
	
	@:describe('Default Command')
	public function testDefault() {
		var command = new EntryCommand();
		return Cli.process(['arg', 'other'], command)
			.map(function(code) return equals(0, code) && equals('defaultAction arg,other', command.result()));
	}
	
	@:describe('Unnamed Command')
	public function testUnnamed() {
		var command = new EntryCommand();
		return Cli.process(['install', 'mypath'], command)
			.map(function(code) return equals(0, code) && equals('install mypath', command.result()));
	}
	
	@:describe('Named Command')
	public function testNamed() {
		var command = new EntryCommand();
		return Cli.process(['uninst', 'mypath', '3'], command)
			.map(function(code) return equals(0, code) && equals('uninstall mypath 3', command.result()));
	}
	
	@:describe('Const Exit Code')
	public function testConstExitCode() {
		var command = new EntryCommand();
		return Cli.process(['const'], command)
			.map(function(code) return equals(1928, code));
	}
	
	@:describe('Any Success')
	public function testAnySuccess() {
		var command = new EntryCommand();
		return Cli.process(['success'], command)
			.map(function(code) return equals(0, code));
	}
	
	@:describe('Any Failure')
	public function testAnyFailure() {
		var command = new EntryCommand();
		return Cli.process(['failure'], command)
			.map(function(code) return equals(1, code));
	}
	
	@:describe('Int Success')
	public function testIntSuccess() {
		var command = new EntryCommand();
		return Cli.process(['successCode'], command)
			.map(function(code) return equals(1928, code));
	}
}

class DebugCommand {
	var debug:String;
	public function new() {}
	public function result() return debug;
}

class EntryCommand extends DebugCommand {
	public var name:String;
	
	@:flag('another-name')
	public var path:String;
	
	@:alias('b')
	public var force:String;
	
	@:command('init2')
	public var init = new InitCommand();
	
	@:command
	public function install(path:String) {
		debug = 'install $path';
	}
	
	@:command('uninst')
	public function uninstall(path:String, retries:Int) {
		debug = 'uninstall $path $retries';
	}
	
	@:defaultCommand
	public function defaultAction(args:Array<String>) {
		debug = 'defaultAction ' + args.join(',');
	}
	
	
	@:command public function const() return 1928;
	@:command public function success() return Success('Done');
	@:command public function failure() return Failure(new Error('Errored'));
	@:command public function successCode() return Success(1928);
}

class InitCommand extends DebugCommand{
	@:defaultCommand
	public function defaultInit(args:Array<String>) {
		trace('defaultInit ' + args.join(','));
		return 9;
	}
}