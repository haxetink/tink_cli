package tink.cli.doc;

import tink.cli.DocFormatter;

class DefaultFormatter implements DocFormatter<String> {
	public function new() {}
	
	public function format(spec:DocSpec):String {
		
		var title = formatDoc(spec.doc, 0, '==============');
		var defaultCommand = null;
		var subs = [];
		var commands = [];
		var flags = [];
		
		for(command in spec.commands) {
			if(command.isDefault) {
				defaultCommand = formatDoc(command.doc);
				continue;
			}
			if(command.isSub) {
				subs.push(formatCommandNames(command.names));
				continue;
			}
			
			commands.push('  ' + formatCommandNames(command.names) + ':\n' + formatDoc(command.doc, 4));
		}
		
		for(flag in spec.flags) {
			var buf = new StringBuf();
			buf.add('  ');
			buf.add(flag.names.join(', '));
			if(flag.aliases.length > 0) buf.add(', ' + flag.aliases.map(function(a) return '-$a').join(', '));
			buf.add(':\n');
			buf.add(formatDoc(flag.doc, 4));
			flags.push(buf.toString());
		}
		
		var out = [
			title + '\n',
			defaultCommand + '\n',
		];
		
		if(subs.length > 0) {
			out.push('Sub Commands:');
			out.push('  ' + subs.join(', '));
			out.push('\n');
		}
		
		if(commands.length > 0) {
			out.push('Commands:');
			out.push(commands.join('\n'));
			out.push('\n');
		}
		
		if(flags.length > 0) {
			out.push('Flags:');
			out.push(flags.join('\n'));
			out.push('\n');
		}
		
		return '\n' + out.join('\n') + '\n';
	}
	
	
	var re = ~/^\s*\*?\s{0,2}(.*)$/;
	
	function formatDoc(doc:String, indent = 2, ?def = '<no doc yet>') {
		var indent = StringTools.lpad('', ' ', indent);
		if(doc == null) return indent + def;
		var lines = doc.split('\n').map(StringTools.trim);
		
		// remove empty lines at the beginning and end
		while(lines[0] == '') lines = lines.slice(1);
		while(lines[lines.length - 1] == '') lines.pop();
		
		return lines
			.map(function(line) return if(re.match(line)) re.matched(1) else line) // trim off leading asterisks
			.map(function(line) return indent + line)
			.join('\n');
	}
	
	function formatCommandNames(names:Array<String>) {
		var out = names[0];
		if(names.length > 1)
			out += ' (' + [for(i in 1...names.length) names[i]].join(', ') + ')';
		return out;
	}
}