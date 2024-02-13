import SlintUI

func test() async {
    print("Hello from the Swift application 🏗️!")

/*
    let capturedValue = Int.random(in: 0...100)

    print("Setting up timer ⏰ (random value: \(capturedValue))")

    let timer = Timer()
    await timer.run(after: 5000) {
        print("Called from event loop 👍 (random value: \(capturedValue))")
    }
*/

    print("Done! 🤓")
}

@main
struct Main: SlintApp {
    static func start() async {
        await test()
    }
}
