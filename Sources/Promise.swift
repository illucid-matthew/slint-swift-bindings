//
// Promise.swift
// slint
//
// Created by Matthew Taylor on 2/12/24.
//

/// Based on: https://stackoverflow.com/a/73082638
final actor Promise<Value> {
    typealias Waiter = CheckedContinuation<Result, Never>

    enum Result {
        case cancelled
        case successful(Value)
    }

    enum Status {
        case pending
        case finished(Result)
    }

    private var waitingRoom = [Waiter]()
    private var status: Status = .pending {
        didSet { resolve() }
    }

    /// Fulfill this promise, resuming anyone waiting.
    public func fulfill(with value: Value)  { status = .finished(.successful(value)) }

    /// Resume all waiting tasks.
    private func resolve() {
        switch status {
        // Pending? Do nothing.
        case .pending:
            return

        // Successful
        case .finished(let result):
            for task in waitingRoom { task.resume(returning: result) }
        }
    }

    /// The resulting value. Await this to be suspended until it's ready.
    public var value: Result {
        get async {
            switch status {
            case .pending:
                return await withCheckedContinuation { waiter in waitingRoom.append(waiter) }
            case .finished(let result):
                return result
            }
        }
    }
}
