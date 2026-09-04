-- Ward encountered a cell visible for planning but not for the LOCEVAL procedure.
-- Turned out to be disapproved during orthofoto evaluation (too small).
--
--
SELECT * FROM "outbound"."LocationAssessments" WHERE grts_address = 72238;

| grts_address | type | cell_disapproved | revisit_disapproval |     disapproval_explanation     |
|--------------+------+------------------+---------------------+---------------------------------|
|        72238 | 7150 | t                | 2025-07-02          | Minimumoppervlakte niet gehaald |


UPDATE "outbound"."LocationAssessments" SET cell_disapproved = FALSE WHERE grts_address = 72238;


-- We gaan dit later nog eens opvolgen en herbekijken. Misschien niet goed dat je de afgekeurde cellen in de planning überhaupt ziet. Maar misschien ook niet slecht.
-- Moest ik er niet zijn, kan je altijd via de orthofoto-app zelf de cel weer goedkeuren.
