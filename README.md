# tink_cli

Write command line tools with ~~ease~~ Haxe.

## Usage

To illustrate the usage, let's look at the follow quick mock-up of the Haxe command line.

```haxe
static function main() {
	Cli.process(Sys.args(), new MockupHaxe()).handle(Cli.exit);
}

@:alias(false)
class MockupHaxe {
	@:flag('-js')
	public var js:String;
	
	@:flag('-lib')
	public var lib:Array<String>;
	
	@:flag('-main')
	public var main:String;
	
	@:flag('-D')
	public var defines:Array<String>;
	
	public var help:Bool;
	
	@:flag('help-defines') 
	public var helpDefines:Bool;
	
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Rest<String>) {
		Sys.println('js: $js');
		Sys.println('lib: $lib');
		Sys.println('main: $main');
		Sys.println('defines: $defines');
		Sys.println('help: $help');
		Sys.println('helpDefines: $helpDefines');
		Sys.println('rest: $rest');
	}
}
```

And then run with:

`./haxe.sh -js bin/run.js -D release -D mobile -lib tink_core -lib tink_json Main`

Gives you:

```
js: bin/run.js
lib: [tink_core,tink_json]
main: null
defines: [release,mobile]
help: null
helpDefines: null
rest: [Main]
```

or: 
`./haxe.sh --help-defines`

```
js: null
lib: null
main: null
defines: null
help: null
helpDefines: true
rest: []
```

Check out the examples folder for the complete code.

### Flags
Every `public var` in the class will be treated as a cli flag.

For example `public var flag:String` will be set to value `<x>` by the cli swtich `--flag <x>`.
Also, the framework will also recognize the first letter of the flag name as alias. So in this case
`-f <x>` will do the same.

You can use metadata data to govern the flag name (`@:flag('my-custom-flag-name')`) and alias (`@:alias('a')`).
Note that you can only use a single charater for alias.

The reason for a single-char restriction for alias is that you can use a condensed alias format, for example:
`-abcdefg` is actually equivalent to `-a -b -c -d -e -f -g`.

If you specify a flag name starting with a single dash (e.g. `@:flag('-flag')`), it will be respected but then
alias support will be automatically disabled. You can also use `@:alias(false)` to manually disable alias,
which works on both field level and class level.

### Commands
Public methods tagged with `@:command` will be treated as a runnable command.

For example `@:command public function run() {}` can be triggered by `./yourscript run`. In case you want to
run a function under your binary name, you can tag a function with `@:defaultCommand`, then you will be able
to run the function with `./yourscript`.

By default the framework infer the command name from the method name,
you can provide a parameter to the metadata like `@:command('my-cmd')` to change that.

Also, if you tag a `public var` with @:command, it will be treated as a sub-command. For instance:

```haxe
@:command
public var sub:AnotherCommand;
```

In this case, when the program is called with `./yourscript sub -a`, 
the default command in `AnotherCommand` will run, with the argument `-a`

### Data Types

By default, Bool, Int, Float and String are supported. Furthermore, you can use any abstract that is castable from String
(i.e. `from String` or `@:from public static function ofString(v:String)`) as the data type.

For example, to use a Map:

```haxe

@:forward
abstract CustomMap(StringMap<Int>) from StringMap<Int> to StringMap<Int> {
	@:from
	public static function fromString(v:String):CustomMap {
		var map = new StringMap<Int>();
		for(i in v.split(',')) switch i.split('=') {
			case [key, value]: map.set(key, (value:tink.Stringly));
			default: throw 'Invalid format';
		}
		return map;
	}
} 
```

Also, note that if a flag is of type Bool, the flag will be set to true without considering the "switch argument",
For example, `--force` is used instead of `--force true` to set `force = true`. In fact in the latter case, the `true`
string is considered as a Rest argument.

Rest argument is a list of strings which are not consumed by the flag parser. You can capture it in a command with
`Rest<String>`. For example:

```haxe
@:defaultCommand
public function run(rest:Rest<String>) {}
```

Note that at most one Rest argument may appear in the list.

### User Input

Besides a non-interaction tool as described above. One can also build an interactive tool, by utilizing the `Prompt` interface.

It is bascally:

```haxe
interface Prompt {
	function prompt(type:PromptType):Promise<String>;
}

enum PromptType {
	Simple(prompt:String);
	MultipleChoices(prompt:String, choices:Array<String>);
}
```

Basically you ask for an input from the user, and then you will get a promised result. It is just an interface
so you can basically implement any mechanism of input, from simple text input to "GUI" input with arrow movements, etc.

For now there is a `SimplePrompt` which basically read from the stdin and take in anything the user gives.
And in case of multiple choice prompt, `RetryPrompt` will make sure the user are choosing from
the provided list of choices, and fail after certain number of retries.

First, you set a `Prompt` instance in `Cli.process(args, command, ?prompt)`
(defaults to a `SimplePrompt` instance if omitted)
and then you can later obtain it back from a command's function like so:

```haxe
@:command
public function run(prompt:tink.cli.Prompt) {
	prompt.prompt('Input your name: ').handle(...);
}
```

### Documentations

```haxe
	var doc = Cli.getDoc(myCommand);
	Sys.println(doc);
```