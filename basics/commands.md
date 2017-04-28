# Command

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