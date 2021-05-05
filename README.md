# NStack 🛠
[![Swift Version](https://img.shields.io/badge/Swift-5.3-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-4-30B6FC.svg)](http://vapor.codes)
[![codebeat badge](https://codebeat.co/badges/f324d1a5-28e1-433e-b71c-a2d2d33bb3ec)](https://codebeat.co/projects/github-com-nodes-vapor-nstack-master)
[![codecov](https://codecov.io/gh/nodes-vapor/nstack/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/nstack)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/nstack)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/nstack)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/nstack/master/LICENSE)

This package is a wrapper around the NStack.io API.

Supports the following NStack modules:

- Localization

## 📦 Installation

### Package.swift

Add `NStack` to the Package dependencies:

```swift
dependencies: [
    // ...,
    .package(url: "https://github.com/nodes-vapor/nstack.git", from: "4.0.0")
]
```

as well as to your target (e.g. "App"):

```swift
targets: [
    .target(name: "App", dependencies: [..., "NStack", ...]),
    // ...
]
```

## Getting started 🚀

### Configuration

In configure.swift:
```swift
import NStack

// [...]

app.caches.use(.memory)
app.nstack.config = NStackConfig(
    applicationName: "my-application",
    applicationID: "my-application-id",
    restKey: "my-secret-key",
    enableLogging: false
)
```

### Cache 🗄

NStack uses the same cache as configured by `app.caches.use()` from Vapor. 
Hence, it is important to set up Vapor's cache if you're using this default behaviour. 
You can use an in-memory cache for Vapor like so:

configure.swift:
```swift
app.cache.use(.memory)
```
#### Custom cache
You can override which cache to use by creating your own type that conforms to the `Cache` protocol from Vapor. 
Use `app.nstack.caches.use()` to configure which cache to use.

### Logging 🗒

Logging in NStack is based Vapors logging API build on top of [SwiftLog](https://github.com/apple/swift-log). 
To turn it on, set `enableLogging: true` when configuring NStack.

## Usage - Features

### Localization
First you'll have to configure your localization. In configure.swift just below where you configured nstack
```swift
// ...
let localizationConfig = LocalizationConfig(
    defaultPlatform: .backend,
    defaultLanguage: "en-EN",
    cacheInMinutes: 60,
    placeholderPrefix: "{",
    placeholderSuffix: "}",
    retryWaitingPeriodInSeconds: 180,
    notFoundWaitingPeriodInSeconds: 300
)

app.nstack.localize = LocalizationClient(
    localizationConfig: localizationConfig,
    nstackConfig: app.nstack.config,
    client: app.client,
    logger: app.logger,
    cache: app.nstack.caches.cache
)
```

Next, to get your localizations. You can either get all localizations for a section or a single localization for a key. 

Get all localizations for a section. If you omit `platform` and `language` it will automatically get your default values as defined in your localization config.
```swift
func getProductSection(req: Request) -> EventLoopFuture<[String: String]> {

    // ...

    let localizations = request.nstack.localize.get(platform: .backend, language: "en-EN", section: "products")

    return localizations
}
```

Get localization for a section/key combination (Using the default platform and section). 
```swift
func getProductSection(req: Request) -> EventLoopFuture<String> {

    // ...

    let localization = request.nstack.localize.get(section: "products", key: "product_name")

    return localization
}
```

You can also provide `searchReplacePairs`:
```swift
func getProductName(req: Request, owner: String) throws -> EventLoopFuture<String> {

    let localization = request.nstack.localize.get(
        section: "products", 
        key: "product_name",
        searchReplacePairs: ["productOwner" : owner]
    )

    return localization
}
```

#### Preload Localizations
The package comes with a middleware that allows you to preload localizations if needed.  
It can be registered either globally in your configure.swift:
```swift
app.middleware.use(NStackPreloadLocalizationsMiddleware())
```
Or on individual routes inside your `routes(app:)`
```swift
let preloadedLocalizations = app.grouped(NStackPreloadLocalizationsMiddleware())
preloadedLocalizations.get("products") { req in
    // This request has passed through NStackPreloadLocalizationsMiddleware.
}
```
NOTE:  `NStackPreloadLocalizationsMiddleware` will only fetch the default language and the default platform localizations.

## 🏆 Credits

This package is developed and maintained by the Vapor team at [Monstarlab](https://monstar-lab.com/global/).

## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
