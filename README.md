# WeeDux

WeeDux is a small implementation of  the **Model** and **Update** aspects of [**TEA**](https://guide.elm-lang.org/architecture/). It's opinionated on how models should be updated and changes propagated.

An application using `WeeDux` 

`WeeDux` specifically ignores the view aspect and treats managing views as an external issue. View rendering is treated as a projection of the model and
moore complex interactions can triggered as a side effect via  `Commad`s.  

## Overview

A `WeeDux` `Program` state is driven by two seperate components:

 - **Model** - current state of the reactor
 - **Messages** - changes that infulence the state of the model. Message are updates in **TEA** terms. The term message is used as they represent something that 
  has happend rather than something you want to happen. This makes modeling a sytem easier than the terms used in other TEA dervatives such as **Action** which could eaily be comfused with command
  
  `WeeDux` also provides an execution environment for async opertions in the form of:
  - **Command**- an async operation that produces messages. `Command` dependencies are supplied by the environment
  - **Environment** - A container for `Command` dependencies
 
 The model is updated as events are applied to the model via an `EventHandler`
