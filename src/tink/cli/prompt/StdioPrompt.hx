package tink.cli.prompt;

import tink.io.Sink;
import tink.io.Source;
import tink.io.IdealSource;
import tink.io.Duplex;
import tink.cli.Prompt;
import haxe.io.*;

using tink.CoreApi;

class StdioPrompt implements Prompt {
	
	var normal:Prompt;
	var secure:Prompt;
	
	public function new() {
		normal = new DuplexPrompt(new Stdio());
		secure = new DuplexPrompt(new SecureStdio());
	}
	
	
	public function print(v:String):Promise<Noise> {
		return normal.print(v);
	}
	
	public function println(v:String):Promise<Noise> {
		return normal.println(v);
	}
	
	public function prompt(type:PromptType):Promise<Stringly> {
		return switch type {
			case Password(_): secure.prompt(type);
			default: normal.prompt(type);
		}
	}
}

class Stdio implements Duplex {
	public var source(get, never):Source;
	public var sink(get, never):Sink;
	
	public function new() {}
	
	public function close() {
		// do nothing, you cannot close stdin/stdout
	}
	
	inline function get_source() return Source.stdin;
	inline function get_sink() return Sink.stdout;
}

class SecureStdio implements Duplex {
	public var source(get, never):Source;
	public var sink(get, never):Sink;
	
	var _source:SyntheticIdealSource;
	public function new() {
		var output = new BytesOutput();
		_source = IdealSource.create();
		
		function next() {
			Source.stdin.limit(1).all().handle(function(o) switch o {
				case Success(bytes): 
					if(!_source.closed) {
						_source.write(bytes);
						('\x1B[2K\x1B[200D':IdealSource).pipeTo(Sink.stdout).handle(next);
					}
				case Failure(e):
					// TODO: do something
			});
		}
		next(); // TODO: this will block in sync enviroments
	}
	
	public function close() {
		_source.closeSafely().eager();
	}
	
	inline function get_source():Source return _source;
	inline function get_sink() return Sink.stdout;
}