import SlintUI

func test() {
    print("Hello from the Swift application 🏗️!")
    test_from_swift()

    print("Setting up timer")

    let timer = Timer()
    timer.run(after: 5000) {
        print("Exiting event loop")
        StopEventLoop()
    }

    print("Starting event loop")
    StartEventLoop()
}

test()
