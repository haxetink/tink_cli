package tink.cli.prompt;

import haxe.io.Bytes;
import tink.io.Sink;
import tink.io.Source;
import tink.cli.Prompt;

using tink.CoreApi;

class SimplePrompt implements Prompt {
	public function new() {}
	
	public function prompt(type:PromptType):Promise<String> {
		
		var display = switch type {
			case Simple(v): '$v: ';
			case MultipleChoices(v, c): '$v [${c.join('/')}]: ';
		}
		
		return (display:Source).pipeTo(Sink.stdout) >>
			function(_) return Source.stdin.split(Bytes.ofString('\n')).a.all() >>
			function(bytes:Bytes) {
				var s = bytes.toString();
				return s.charCodeAt(s.length - 1) == '\r'.code ? s.substr(0, s.length - 1) : s;
			}
	}
}