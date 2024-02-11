import SlintUI

func test() {
    print("Hello from the Swift application 🏗️!")
    test_from_swift()

    let capturedValue = Int.random(in: 0...100)

    print("Setting up timer ⏰ (random value: \(capturedValue))")

    let timer = Timer()
    timer.run(after: 5000) {
        print("Called from event loop 👍 (random value: \(capturedValue))")
        StopEventLoop()
    }

    print("Starting event loop 🔁")
    StartEventLoop()

    print("Done! 🤓")
}

test()
