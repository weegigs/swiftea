# WeeDux

WeeDux is a small implementation of  the **Model** and **Update** aspects of [**TEA**](https://guide.elm-lang.org/architecture/).

`WeeDux` has a companion library `SwifTEA` which provides integration components for `SwiftUI`

## Installation

`WeeDux` is available via the swift package manager.

```
dependencies: [
  .Package(url: https://github.com/weegigs/weedux.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

## Examples

* [**QOTD**](https://github.com/weegigs/qotd) - An example application using `WeeDux`, `SwifTEA` and `SwiftUI`.

## Overview

> The documentation below is only partially complete. Slides from the the talk
[SwifTEA UI - Unidirectional dataflow with SwiftUI and WeeDux](https://www.slideshare.net/KevinONeill1/swiftea-ui-unidirectional-data-flow-with-swiftui-and-weedux) at the Melbourne CocoaHeads meetup in August 2019 are available on [SlideShare](https://www.slideshare.net/KevinONeill1/swiftea-ui-unidirectional-data-flow-with-swiftui-and-weedux)

A `WeeDux` `Program` state is driven by two separate components:

* **Model** - current state of the reactor
* **Messages** - changes that influence the state of the model. Message are updates in **TEA** terms. The term message is used as they represent something that has happened rather than something you want to happen. This makes modeling a system easier than the terms used in other TEA derivatives such as **Action** which is a little ambiguous and could easily be confused with command
  
`WeeDux` also provides an execution environment for operations that rely on external components (i.e. state that is not directly managed via messages) in the form of:

* **Command** - an async operation that produces messages. `Command` dependencies are supplied by the environment
* **Environment** - A container for `Command` dependencies

The model is updated as events are applied to the model via a `MessageHandler`
