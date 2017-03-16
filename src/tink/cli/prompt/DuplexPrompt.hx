package tink.cli.prompt;

import haxe.io.Bytes;
import tink.Stringly;
import tink.io.Sink;
import tink.io.Source;
import tink.io.IdealSource;
import tink.io.Duplex;
import tink.cli.Prompt;

using tink.CoreApi;

class DuplexPrompt implements Prompt {
	
	var duplex:Duplex;
	
	public function new(duplex) {
		this.duplex = duplex;
	}
	
	public function print(v:String):Promise<Noise> {
		return (v:IdealSource).pipeTo(duplex.sink).map(function(r) return switch r {
			case AllWritten: Success(Noise);
			default: Failure(Error.withData('Pipe Error', r));
		});
	}
	
	public function println(v:String):Promise<Noise> {
		return print('$v\n');
	}
	
	public function prompt(type:PromptType):Promise<Stringly> {
		
		var display = switch type {
			case Simple(v) | Password(v): '$v: ';
			case MultipleChoices(v, c): '$v [${c.join('/')}]: ';
		}
		
		return (display:IdealSource).pipeTo(duplex.sink) >>
			function(_) return duplex.source.split(Bytes.ofString('\n')).a.all() >>
			function(bytes:Bytes) {
				var s = bytes.toString();
				return s.charCodeAt(s.length - 1) == '\r'.code ? s.substr(0, s.length - 1) : s;
			}
	}
}