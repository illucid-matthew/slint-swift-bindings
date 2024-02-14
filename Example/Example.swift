import SlintUI

func test() async {
    print("Hello from the Swift application 🏗️!")

    let capturedValue = Int.random(in: 0...100)

    let channel = AsyncChannel(Void.self)

    let timer = Timer()

    print("🚨 Setting up timer")
    timer.willRun(after: 100) {
        print("Called from event loop 👍 (random value: \(capturedValue))")
    }

    try! await Task.sleep(nanoseconds: 550_000_000)
    print("✨")

    print("🚨 Setting a different timer")
    timer.willRun(after: 100) {
        print("2 Called from event loop 👍 (random value: \(capturedValue))")
    }

    print("Done! 🤓")
}

@main
struct Main: SlintApp {
    static func start() async {
        // await EventLoop.run { print("Hello from EventLoop.run!") }
        await test()
    }
}
