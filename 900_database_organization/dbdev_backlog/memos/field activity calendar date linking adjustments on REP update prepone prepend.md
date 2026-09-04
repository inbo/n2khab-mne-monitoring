---
aliases:
tags:
  - calendar
  - activities
  - prepone
  - prepend
---


### prepone and prepend

*summary by #FV [[timeline/2026-03-20|2026-03-20]]:*
- vervroegbaar = #preponable. Dus naar voor schuiven van een reeds  geplande activiteit, dus datums worden vervroegd.
     + mogelijk voor regex "LOCEVAL|INST|SPATPOSIT"
     + In de praktijk wordt dit niet actief gedaan voor LOCEVAL's omdat een 'recente' LOCEVAL altijd meer betrouwbaar is. We doen het momenteel dus alleen bij INST|SPATPOSIT. 
        (Deze stellingen gelden voor de veldwerkkalender die uit de REP & code snippets voortkomen en die je gebruikt, maar de REP zelf heeft herhaalde LOCEVAL's op dezelfde locatie wel gerationaliseerd naar 'de vroegst nodige')
- 'aanvulbaar vooraan' = #prependable. Dus aanvullen met extra occasions vooraan, zonder te verschuiven wat reeds in de planning zit
     + mogelijk voor regex "LEVREADDIVER"