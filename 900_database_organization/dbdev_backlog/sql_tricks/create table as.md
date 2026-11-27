---
aliases:
  - CREATE TABLE AS
  - CREATE TABLE ... AS
  - SELECT INTO
tags:
  - sql
---

`CREATE TABLE <table> AS <query>;` is a method to store the result of a query into a newly created table.
It is related to the `SELECT INTO` but preferred due to syntax ambiguity of `INTO` in some #postgresql dialects.

+ [documentation](https://www.postgresql.org/docs/current/sql-createtableas.html)


A useful purpose of this is the creation of backup tables for a structural overhaul, which might be a combination of existing information from different tables. Example:
+ [[overhaul mnmsurfdb field forms preparing 2027 Q1 campaign#Unused `*Observations` Tables|backup unused Observations tables]]