import Vapor

public extension Application {
    struct NStack {
        private struct Key: StorageKey {
            typealias Value = Storage
        }

        private let application: Application

        private final class Storage {
            var makeCache: ((Application) -> Cache)? = nil
            var config: NStackConfig? = nil
            var localize: LocalizationController? = nil
            init() {}
        }

        init(application: Application) {
            self.application = application
        }

        private var storage: Storage {
            if application.storage[Key.self] == nil {
                initialize()
            }

            return application.storage[Key.self]!
        }

        private func initialize() {
            application.storage[Key.self] = Storage()
            application.nstack.caches.use(.default)
        }

        public var config: NStackConfig {
            get {
                guard let config = storage.config else {
                    fatalError("NStack isn't configured, use: app.nstack.config = ...")
                }

                return config
            }
            nonmutating set { storage.config = newValue }
        }

        public var localize: LocalizationController {
            get {
                guard let localize = storage.localize else {
                    fatalError("NStack localize isn't configured, use: app.nstack.localize = ...")
                }

                return localize
            }
            nonmutating set { storage.localize = newValue }
        }
    }

    var nstack: NStack {
        .init(application: self)
    }
}

// MARK: - NStack + Caches

extension Application.NStack {
    public struct Caches {
        private let nstack: Application.NStack

        public init(_ nstack: Application.NStack) {
            self.nstack = nstack
        }

        public struct Provider {
            public let run: (Application) -> Void

            public init(_ run: @escaping (Application) -> Void) {
                self.run = run
            }

            /// A provider that uses the default Vapor cache.
            public static var `default`: Self {
                .init { application in
                    application.nstack.caches.use { $0.cache }
                }
            }
        }

        public func use(_ makeCache: @escaping (Application) -> Cache) {
            nstack.storage.makeCache = makeCache
        }

        public func use(_ provider: Provider) {
            provider.run(nstack.application)
        }

        public var cache: Cache {
            guard let factory = nstack.storage.makeCache else {
                fatalError("NStack cache isn't configured, use: app.nstack.caches.use(...)")
            }

            return factory(nstack.application)
        }
    }

    public var caches: Caches {
        .init(self)
    }
}
