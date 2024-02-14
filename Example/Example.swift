import SlintUI

func test() async {
    print("Hello from the Swift application 🏗️!")

    let timer = Timer()

    let channel1 = AsyncChannel(Void.self)

    print("🚨 Setting up timer")
    timer.willRun(after: 1000) {
        print("👍 The first timer was ran!")
        channel1.send()
    }

    print("⏰ Waiting for the first timer to fire…")
    try! await channel1.value

    let channel2 = AsyncChannel(Void.self)
    print("🚨 Setting a different timer")
    timer.willRun(after: 1500) {
        print("👍 The second timer was ran!")
        channel2.send()
    }

    try! await channel2.value

    timer.willRun(every: 1000) {
        print("🐦‍⬛ Is this getting annoying?")
    }

    print("🤓 Done!")
}

@main
struct Main: SlintApp {
    static func start() async {
        // await EventLoop.run { print("Hello from EventLoop.run!") }
        await test()
    }
}
