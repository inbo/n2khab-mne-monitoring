---
aliases:
tags:
  - loceval
  - localreplacements
  - SampleUnits
  - Visits
started:
finished:
execution:
status: false
---

Currently, replacement happens on the level of the #SampleUnits.
However, repeated #Visits can create different outcomes: replacements might be temporary, replacement cell might be replaced by themselves, and so forth.

Though technically, the replacement is efficiently stored on Units level, we must implement a way to keep track of replacement alterations.