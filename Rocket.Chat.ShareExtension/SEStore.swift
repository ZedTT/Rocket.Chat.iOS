//
//  SEDatabase.swift
//  Rocket.Chat.ShareExtension
//
//  Created by Matheus Cardoso on 3/1/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import Foundation

private func getServers() -> [(name: String, host: String)] {
    return DatabaseManager.servers?.flatMap {
        guard
            let name = $0[ServerPersistKeys.serverName],
            let host = URL(string: $0[ServerPersistKeys.serverURL] ?? "")?.host
        else {
            return nil
        }

        return (name, host)
    } ?? []
}

private func getRooms(serverIndex: Int) -> [Subscription] {
    guard let realm = DatabaseManager.databaseInstace(index: serverIndex) else { return [] }
    return Array(realm.objects(Subscription.self).map(Subscription.init))
}

protocol SEStoreSubscriber: class {
    func storeUpdated(_ store: SEStore)
}

final class SEStore {
    var servers = getServers() {
        didSet {
            notifySubscribers()
        }
    }

    var selectedServerIndex: Int = 0 {
        didSet {
            rooms = getRooms(serverIndex: selectedServerIndex)
            notifySubscribers()
        }
    }

    var scenes: [SEScene] = [.rooms] {
        didSet {
            notifySubscribers()
        }
    }

    var sceneTransition: SESceneTransition = .none {
        didSet {
            notifySubscribers()
        }
    }

    var rooms = getRooms(serverIndex: 0) {
        didSet {
            notifySubscribers()
        }
    }

    var currentRoom = Subscription() {
        didSet {
            notifySubscribers()
        }
    }

    var composeText = "" {
        didSet {
            notifySubscribers()
        }
    }

    private var subscribers = [SEStoreSubscriber]()

    func subscribe(_ subscriber: SEStoreSubscriber) {
        guard !subscribers.contains(where: { $0 === subscriber }) else {
            return
        }

        subscribers.append(subscriber)
        subscriber.storeUpdated(self)
    }

    func unsubscribe(_ subscriber: SEStoreSubscriber) {
        guard let index = subscribers.index(where: { $0 === subscriber }) else {
            return
        }

        subscribers.remove(at: index)
    }

    func notifySubscribers() {
        subscribers.forEach {
            $0.storeUpdated(self)
        }
    }
}

let store = SEStore()