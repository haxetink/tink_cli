# User Input

To build an interactive tool, on can utilize the `Prompt` interface.

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