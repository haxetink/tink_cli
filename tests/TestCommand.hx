package;

import tink.cli.*;
import tink.Cli;
import tink.unit.Assert.*;

using tink.CoreApi;

@:asserts
class TestCommand {
	public function new() {}
	
	
	@:describe('Default Command')
	public function testDefault() {
		var command = new EntryCommand();
		
		return Cli.process(['arg', 'other'], command)
			.map(function(code) return assert(command.result() == 'defaultAction arg,other'));
	}
	
	@:describe('Unnamed Command')
	public function testUnnamed() {
		var command = new EntryCommand();
		return Cli.process(['install', 'mypath'], command)
			.map(function(code) return assert(command.result() == 'install mypath'));
	}
	
	@:describe('Named Command')
	public function testNamed() {
		var command = new EntryCommand();
		return Cli.process(['uninst', 'mypath', '3'], command)
			.map(function(code) return assert(command.result() == 'uninstall mypath 3'));
	}
	
	@:describe('Sub Command')
	public function testSub() {
		var command = new EntryCommand();
		return Cli.process(['init', 'a', 'b', 'c'], command)
			.map(function(code) return assert(command.init.result() == 'defaultInit a,b,c'));
	}
	
	@:describe('Multi Name')
	@:variant('multi1')
	@:variant('multi2')
	public function testMultiName(cmd:String) {
		var command = new EntryCommand();
		return Cli.process([cmd], command)
			.map(function(_) return assert(command.result() == 'multi'));
	}

	@:describe('Multi with "" taking name from function')
	@:variant('multi_again1')
	@:variant('multi_again2')
	@:variant('multi_again')
	public function testMultiNameAgain(cmd:String) {
		var command = new EntryCommand();
		return Cli.process([cmd], command)
			.map(function(_) return assert(command.result() == 'multi_again'));
	}
	
	@:describe('Rest Arguments')
	@:variant(['rest', 'a', 'b'], null)
	@:variant(['rest', 'a', 'b', 'c'], 'rest a b  c')
	@:variant(['rest', 'a', 'b', 'c', 'd'], 'rest a b c d')
	@:variant(['rest', 'a', 'b', 'c', 'd', 'e'], 'rest a b c,d e')
	public function testRest(cmd:Array<String>, result:String) {
		var command = new EntryCommand();
		return Cli.process(cmd, command)
			.map(function(_) return assert(command.result() == result));
	}
	
	@:describe('Const Result')
	public function testConst() {
		var command = new EntryCommand();
		return Cli.process(['const'], command)
			.map(function(o) return assert(o.isSuccess()));
	}
	
	@:describe('Success Result')
	public function testSuccess() {
		var command = new EntryCommand();
		return Cli.process(['success'], command)
			.map(function(o) return assert(o.isSuccess()));
	}
	
	@:describe('Failure Result')
	public function testFailure() {
		var command = new EntryCommand();
		return Cli.process(['failure'], command)
			.map(function(result) return assert(!result.isSuccess()));
	}
	
	@:describe('Future Const Result')
	public function testFutureConst() {
		var command = new EntryCommand();
		return Cli.process(['futureConst'], command)
			.map(function(o) return assert(o.isSuccess()));
	}
	
	@:describe('Future Success Result')
	public function testFutureSuccess() {
		var command = new EntryCommand();
		return Cli.process(['futureSuccess'], command)
			.map(function(o) return assert(o.isSuccess()));
	}
	
	@:describe('Future Failure Result')
	public function testFutureFailure() {
		var command = new EntryCommand();
		return Cli.process(['futureFailure'], command)
			.map(function(result) return assert(!result.isSuccess()));
	}
	
}

class EntryCommand extends DebugCommand {
	
	@:command('init')
	public var init = new InitCommand();
	
	@:command
	public function install(path:String) {
		debug = 'install $path';
	}
	
	@:command('uninst')
	public function uninstall(path:String, retries:Int) {
		debug = 'uninstall $path $retries';
	}
	
	@:command('multi1', 'multi2')
	public function multi() {
		debug = 'multi';
	}

	@:command('', 'multi_again1', 'multi_again2')
	public function multi_again() {
		debug = 'multi_again';
	}

	@:command
	public function rest(a:String, b:String, c:Rest<String>, d:String) {
		debug = 'rest $a $b ${c.join(',')} $d';
	}
	
	@:defaultCommand
	public function defaultAction(args:Rest<String>) {
		debug = 'defaultAction ' + args.join(',');
	}
	
	
	@:command public function const() return 'Done';
	@:command public function success() return Success('Done');
	@:command public function failure() return Failure(new Error('Errored'));
	@:command public function futureConst() return Future.sync('Done');
	@:command public function futureSuccess() return Future.sync(Success('Done'));
	@:command public function futureFailure() return Future.sync(Failure(new Error('Errored')));
}

class InitCommand extends DebugCommand{
	@:defaultCommand
	public function defaultInit(args:Rest<String>) {
		debug = 'defaultInit ' + args.join(',');
	}
}
