package;

import tink.cli.*;
import tink.Cli;
import tink.unit.Assert.*;
import haxe.ds.StringMap;

using tink.CoreApi;

@:asserts
class TestDoc {
	public function new() {}

	public function doc() {
		var command = new FlagDoc();

		var result = 
		'\n' + 
		'  Usage: root\n\n' +
		'  Flags:\n' +
		'  --name, -n   : No parameter\n' +
		'  --path, -p <directory>            : Do search in path\n' +
		'  --unusedParameter, -u <parameter> : Do search in path\n';

		result = StringTools.replace(result, " ", "");
		asserts.assert(result == StringTools.replace(Cli.getDoc(command, new tink.cli.doc.DefaultFormatter("root")), " ", ""));	
		return asserts.done();
	}
}

class FlagDoc extends DebugCommand {
	
	/**
        No parameter
    **/
	@:flag('name')	
	public var name:String = null;
	
	/**
        @param <directory>
        Do search in path
	**/
	@:flag('path')	
	public var path:String = null;

	/**
        @param <parameter>
        Do search in path
        @param unused parameter
    **/
	@:flag('unusedParameter')	
	public var unusedParameter:String = null;

	@:defaultCommand
	public function run(args:Rest<String>) {}
}