package tink.cli.doc;

import tink.cli.DocFormatter;

using Lambda;
using StringTools;

class DefaultFormatter implements DocFormatter<String> {
	
	var root:String;
	
	public function new(?root) {
		this.root = root;
	}
	
	public function format(spec:DocSpec):String {
		var out = new StringBuf();
		inline function addLine(v:String) out.add(v + '\n');
		
		// title
		addLine('');
		switch formatDoc(spec.doc) {
			case null:
			case doc: addLine('$doc\n');
		}
		
		var subs = spec.commands.filter(function(c) return !c.isDefault);
		var flags = [];
		
		if(root != null) addLine('  Usage: $root');
		
		switch spec.commands.find(function(c) return c.isDefault) {
			case null:
			case defaultCommand:
				switch formatDoc(defaultCommand.doc) {
					case null:
					case doc: addLine(indent(doc, 4) + '\n');
				}
		}
		
		if(subs.length > 0) {
			var maxCommandLength = subs.fold(function(command, max) {
				for(name in command.names) if(name.length > max) max = name.length;
				return max;
			}, 0);
			
			if(root != null) addLine('  Usage: $root <subcommand>');
			addLine('    Subcommands:');
			
			function addCommand(name:String, doc:String) {
				if(doc == null) doc = '(doc missing)';
				addLine(indent(name.lpad(' ', maxCommandLength) + ' : ' + indent(doc, maxCommandLength + 3).trim(), 6));
			}
			
			for(command in subs) {
				var name = command.names[0];
				addCommand(name, formatDoc(command.doc));
				
				if(command.names.length > 1)
					for(i in 1...command.names.length)
						addCommand(command.names[i], 'Alias of $name');
			}
		}
		
		if(spec.flags.length > 0) {
			function nameOf(flag:DocFlag) {
				var variants = flag.names.join(', ');
				if(flag.aliases.length > 0) variants += ', ' + flag.aliases.map(function(a) return '-$a').join(', ');
				return variants;
			}
			
			var maxFlagLength = spec.flags.fold(function(flag, max) {
				var name = nameOf(flag);
				if(flag.paramDescription.length > 0) name += ' ${flag.paramDescription}';
				if(name.length > max) max = name.length;
				return max;
			}, 0);
			
			var ep = ~/^@param.*$/gim;
			function addFlag(name:String, doc:String, paramDescription:String) {
				if(doc == null) {
					doc = '';
				} else {
					//Filter out the lines with @param
					doc = ep.map(doc, function(e : EReg) return "");
				}
				addLine(indent(('$name $paramDescription').rpad(' ', maxFlagLength) +  ' : ' + indent(doc, maxFlagLength + 3).trim(), 6));
			}
			
			addLine('');
			addLine('  Flags:');
			
			for(flag in spec.flags) {
				addFlag(nameOf(flag), formatDoc(flag.doc), flag.paramDescription);
			}
		}
		
		return out.toString();
	}
	
	function indent(v:String, level:Int) {
		return v.split('\n').map(function(v) return ''.lpad(' ', level) + v).join('\n');
	}
	
	var re = ~/^\s*\*?\s{0,2}(.*)$/;
	function formatDoc(doc:String) {
		if(doc == null) return null;
		var lines = doc.split('\n').map(StringTools.trim);
		
		// remove empty lines at the beginning and end
		while(lines[0] == '') lines = lines.slice(1);
		while(lines[lines.length - 1] == '') lines.pop();
		
		return lines
			.map(function(line) return if(re.match(line)) re.matched(1) else line) // trim off leading asterisks
			.join('\n');
	}
}