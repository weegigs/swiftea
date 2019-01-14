# WeeDux

WeeDux is a small implementation of  the **Model** and **Update** aspects of [**TEA**](https://guide.elm-lang.org/architecture/). 

An application using `WeeDux` 

`WeeDux` specifically ignores the view aspect and treats managing views as an external issue. View rendering is treated as a projection of the model and
moore complex interactions can triggered as a side effect via  `Commad`s.  

## Overview

A `WeeDux` `Reactor` state driven by two seperate components:
 - **Model** - current state of the reactor
 - **Events** - changes that infulence the state of the model. Events are updates in **TEA** terms. The term event is used as they represent something that 
  has happend rather than something you want to happen. This makes modeling a sytem easier than the terms used in other TEA dervatives such as **Action**
 
 The model is updated as events are applied to the model via an `EventHandler`
