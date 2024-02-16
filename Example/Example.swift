import Foundation
import SlintUI

let startTime = ProcessInfo.processInfo.systemUptime
var timeSinceStart: String { String(format: "%.5f", Double(ProcessInfo.processInfo.systemUptime - startTime)) }

func test() async {
    print("Hello from the Swift application 🏗️!")

    print("Timer 1 ⏰ should fire once after 3 second.")
    print("Timer 2 🐦‍⬛ should fire every 750 milliseconds, and be stopped by timer 3.")
    print("Timer 3 ⏲️  should fire after 5 seconds after timer 1.")

    let timer1 = SlintTimer()
    let timer2 = SlintTimer()
    let timer3 = SlintTimer()

    let channel = AsyncChannel(Void.self)

    // Setup the first timer.
    await timer1.willRun(after: 3000) {
        print("[\(timeSinceStart)] ⏰ The first timer was ran!")
        channel.send()
    }

    await timer2.willRun(every: 750) {
        print("[\(timeSinceStart)] 🐦‍⬛ Is this getting annoying?")
    }

    // Setup the second timer from a task.
    Task {
        try! await channel.value
        await timer2.stop()
        await timer3.willRun(after: 5000) {
            print("[\(timeSinceStart)] ⏲️  The third timer was ran!")
            timer2.restart()
        }
    }

    print("🤓 Done!")
    print("❓ Timer 3 running? \(await timer3.running)")
}

@main
struct Main: SlintApp {
    static func start() async {
        // await EventLoop.run { print("Hello from EventLoop.run!") }
        await test()
    }
}
