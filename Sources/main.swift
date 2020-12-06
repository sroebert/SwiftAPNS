import ConsoleKit
import Foundation

let console = Terminal()
var input = CommandInput(arguments: CommandLine.arguments)
var context = CommandContext(console: console, input: input)

var commands = Commands(enableAutocomplete: true)
commands.use(SendSimplePushNotificationCommand(), as: "simple", isDefault: true)

do {
    let group = commands
        .group(help: "A simple command line tool for testing Apple push notifications.")
    try console.run(group, input: input)
} catch let error {
    console.error("\(error)")
    exit(1)
}
