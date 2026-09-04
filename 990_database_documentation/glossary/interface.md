see [wikipedia](https://en.wikipedia.org/wiki/Interface_(object-oriented_programming))

In object-oriented programming, more specifically when using [[sql/inheritance|inheritance]], an **interface** describes a special type of parent table which by itself is not intended to hold data, but which defines the variables and methods that are common to a set of subclasses.

In the case of our database, interface tables collect a set of columns which are common to multiple other tables of similar purpose. 
The derived tables usually add extra columns, except for the occasionally used "Other*" tables which aggregates data that is not otherwise categorized.

Examples are #Visits and #Observations.