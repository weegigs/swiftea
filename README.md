# SwifTEA

[![Build status](https://badge.buildkite.com/e09f9a2d6ef9d2393b23b1cc4d291cf844ec59198b1d3a3ca2.svg)](https://buildkite.com/weegigs/swiftea)

SwifTEA is a small implementation of  the **Model** and **Update** aspects of [**TEA**](https://guide.elm-lang.org/architecture/).

`SwifTEA` has a companion library `SwifTEAUI` which provides integration components for `SwiftUI`

## Semantic Versioning

**SwifTEA** uses [semantic versioning](https://semver.org). Until version `1.0.0` breaking changes may be introduced on minor version number changes. Bug fixes and backward compatible features will be added on patch versions. You should take this into account when setting your package dependency details.

## Installation

`SwifTEA` is available via the swift package manager.

```swift
dependencies: [
  .package(url: "https://github.com/weegigs/swiftea.git", .upToNextMinor(from: "0.13.0"))
]
```

## Examples

* [**QOTD**](https://github.com/weegigs/qotd) - An example application using `SwifTEA`, `SwifTEAUI` and `SwiftUI`.

## Overview

> The documentation below is only partially complete. Slides from the the talk
[SwifTEA UI - Unidirectional dataflow with SwiftUI and SwifTEA](https://www.slideshare.net/KevinONeill1/swiftea-ui-unidirectional-data-flow-with-swiftui-and-SwifTEA) at the Melbourne CocoaHeads meetup in August 2019 are available on [SlideShare](https://www.slideshare.net/KevinONeill1/swiftea-ui-unidirectional-data-flow-with-swiftui-and-SwifTEA)

A `SwifTEA` `Program` state is driven by two separate components:

* **Model** - current state of the program
* **Messages** - changes that influence the state of the model. Message are updates in **TEA** terms. I use the term message is used as they represent something that has happened rather than something you want to happen. This makes modeling a system easier than the terms used in other TEA derivatives such as **Action** which is a little ambiguous and could easily be confused with command
  
`SwifTEA` also provides an execution environment for operations that rely on external components (i.e. state that is not directly managed via messages) in the form of:

* **Command** - an async operation that produces messages. `Command` dependencies are supplied by the environment
* **Environment** - A container for `Command` dependencies

## Basic Operation

The model is updated as **messages** are applied to the model via a `MessageHandler`.

In it's most fundamental form a `MessageHandler` is a function `(Model[^1], Message) -> (Model[^1], Command)`. It takes a `Model` and a `Message` and produces a new `Model` along with any side effects you want to trigger in the form of a `Command`.

`SwifTEA` provides a simplified `MessageHandler`, `Reducer` that lacks the `Command` output. This helps with the ergonomics when creating a `MessageHandler` that simply updates the `Model`

## WeeDux

`SwifTEA` started life as a `FLUX` style library and the name `WeeDux` fit nicely with the theme (a small `Flux` library). It was quickly apparent to me that without explicit side effect handling I was leaving a lot of usefulness on the table. By moving to an `Elm` styled approach I was able to create a specific place to manage side effects and, as a bonus, manage dependency injection for side effect producing operations. Though the base architectural approach had changed I stuck with `WeeDux` name because that was the name I had.

When [@mattdelves](https://twitter.com/mattdelves) suggested **SwifTEA UI** for the name of my talk on combining `WeeDux` with `SwiftUI`, like the original architectural change, the name change was apparent.

## License

MIT License

Copyright (c) 2019 Kevin O'Neill

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Footnotes

[^1]: The model is passed as an `inout` variable for ergonomic reasons
