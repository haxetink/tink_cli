package tink.cli.prompt;

import haxe.io.Bytes;
import tink.io.Sink;
import tink.io.Source;
import tink.io.Duplex;
import tink.cli.Prompt;

using tink.CoreApi;

class DuplexPrompt implements Prompt {
	
	var duplex:Duplex;
	
	public function new(duplex) {
		this.duplex = duplex;
	}
	
	public function prompt(type:PromptType):Promise<String> {
		
		var display = switch type {
			case Simple(v): '$v: ';
			case MultipleChoices(v, c): '$v [${c.join('/')}]: ';
		}
		
		return (display:Source).pipeTo(duplex.sink) >>
			function(_) return duplex.source.split(Bytes.ofString('\n')).a.all() >>
			function(bytes:Bytes) {
				var s = bytes.toString();
				return s.charCodeAt(s.length - 1) == '\r'.code ? s.substr(0, s.length - 1) : s;
			}
	}
}