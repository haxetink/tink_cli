package tink.cli.prompt;

import haxe.io.Bytes;
import tink.Stringly;
import tink.io.Sink;
import tink.cli.Prompt;

using tink.io.Source;
using tink.CoreApi;

class IoPrompt implements Prompt {
	
	var source:RealSource;
	var sink:RealSink;
	
	public function new(source, sink) {
		this.source = source;
		this.sink = sink;
	}
	
	public function print(v:String):Promise<Noise> {
		return (v:IdealSource).pipeTo(sink).map(function(r) return switch r {
			case AllWritten: Success(Noise);
			default: Failure(Error.withData('Pipe Error', r));
		});
	}
	
	public function println(v:String):Promise<Noise> {
		return print('$v\n');
	}
	
	public function prompt(type:PromptType):Promise<Stringly> {
		
		var secure = false;
		var display = switch type {
			case Simple(v): '$v: ';
			case Secure(v): secure = true; '$v: ';
			case MultipleChoices(v, c): '$v [${c.join('/')}]: ';
		}
		
		return (display:IdealSource).pipeTo(sink).flatMap(function(o):Promise<Stringly> return switch o {
			case AllWritten:
				if(secure) secureInput(display);
				else {
					var split = source.split('\n');
					source = split.after;
					split.before.all()
						.next(function(chunk) {
							var s = chunk.toString();
							return s.charCodeAt(s.length - 1) == '\r'.code ? s.substr(0, s.length - 1) : s;
						});
				}
			default:
				new Error('');
		});
	}
	
	function secureInput(prompt:String):Promise<Stringly>
		throw 'not implemented';
}