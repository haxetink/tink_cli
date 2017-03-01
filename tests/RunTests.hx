package ;

class RunTests {

	static function main() {
		var args = Sys.args();
		#if interp Sys.setCwd(args.pop()) #end
		
		args = ['uninstall', 'b', '2'];
		tink.Cli.process(args, new TestCommand()).handle(travix.Logger.exit);
	}

}

class TestCommand {
	public var name:String;
	
	@:flag('another-name')
	public var path:String;
	
	@:alias('b')
	public var force:String;
	
	@:command('init')
	public var init = new InitCommand();
	
	public function new() {}
	
	@:command
	public function install(path:String) {
		trace('install $path');
		return 0;
	}
	
	@:command
	public function uninstall(path:String, retries:Int) {
		trace('uninstall $path $retries');
		return 0;
	}
	
	@:defaultCommand
	public function defaultAction(args:Array<String>) {
		trace('defaultAction $args');
		return 9;
	}
}

class InitCommand {
	public function new() {}
}