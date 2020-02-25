
\copy SCHEMA.concept from 'CONCEPT.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.concept_ancestor from 'CONCEPT_ANCESTOR.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.concept_class from 'CONCEPT_CLASS.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.concept_relationship from 'CONCEPT_RELATIONSHIP.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.concept_synonym from 'CONCEPT_SYNONYM.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.domain from 'DOMAIN.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.drug_strength from 'DRUG_STRENGTH.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.relationship from 'RELATIONSHIP.csv' quote E'\b' delimiter E'\t' csv header
\copy SCHEMA.vocabulary from 'VOCABULARY.csv' quote E'\b' delimiter E'\t' csv header
