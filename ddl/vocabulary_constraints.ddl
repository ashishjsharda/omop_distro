/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

/************************

OMOP VOCABULARY v5.3 constraints

postgresql script to create foreign key constraints within OMOP common data model, version 5.3.0

last revised: 14-June-2018

author:  Patrick Ryan, Clair Blacketer


*************************/


/************************
*************************
*************************
*************************

Foreign key constraints

*************************
*************************
*************************
************************/


/************************

Standardized vocabulary

************************/


ALTER TABLE vocabulary.concept ADD CONSTRAINT fpk_concept_domain FOREIGN KEY (domain_id)  REFERENCES vocabulary.domain (domain_id);

ALTER TABLE vocabulary.concept ADD CONSTRAINT fpk_concept_class FOREIGN KEY (concept_class_id)  REFERENCES vocabulary.concept_class (concept_class_id);

ALTER TABLE vocabulary.concept ADD CONSTRAINT fpk_concept_vocabulary FOREIGN KEY (vocabulary_id)  REFERENCES vocabulary.vocabulary (vocabulary_id);

ALTER TABLE vocabulary.vocabulary ADD CONSTRAINT fpk_vocabulary_concept FOREIGN KEY (vocabulary_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.domain ADD CONSTRAINT fpk_domain_concept FOREIGN KEY (domain_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_class ADD CONSTRAINT fpk_concept_class_concept FOREIGN KEY (concept_class_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_relationship ADD CONSTRAINT fpk_concept_relationship_c_1 FOREIGN KEY (concept_id_1)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_relationship ADD CONSTRAINT fpk_concept_relationship_c_2 FOREIGN KEY (concept_id_2)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_relationship ADD CONSTRAINT fpk_concept_relationship_id FOREIGN KEY (relationship_id)  REFERENCES vocabulary.relationship (relationship_id);

ALTER TABLE vocabulary.relationship ADD CONSTRAINT fpk_relationship_concept FOREIGN KEY (relationship_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.relationship ADD CONSTRAINT fpk_relationship_reverse FOREIGN KEY (reverse_relationship_id)  REFERENCES vocabulary.relationship (relationship_id);

ALTER TABLE vocabulary.concept_ancestor ADD CONSTRAINT fpk_concept_ancestor_concept_1 FOREIGN KEY (ancestor_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_ancestor ADD CONSTRAINT fpk_concept_ancestor_concept_2 FOREIGN KEY (descendant_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.source_to_concept_map ADD CONSTRAINT fpk_source_to_concept_map_v_1 FOREIGN KEY (source_vocabulary_id)  REFERENCES vocabulary.vocabulary (vocabulary_id);

ALTER TABLE vocabulary.source_to_concept_map ADD CONSTRAINT fpk_source_concept_id FOREIGN KEY (source_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.source_to_concept_map ADD CONSTRAINT fpk_source_to_concept_map_v_2 FOREIGN KEY (target_vocabulary_id)  REFERENCES vocabulary.vocabulary (vocabulary_id);

ALTER TABLE vocabulary.source_to_concept_map ADD CONSTRAINT fpk_source_to_concept_map_c_1 FOREIGN KEY (target_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT fpk_drug_strength_concept_1 FOREIGN KEY (drug_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT fpk_drug_strength_concept_2 FOREIGN KEY (ingredient_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT fpk_drug_strength_unit_1 FOREIGN KEY (amount_unit_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT fpk_drug_strength_unit_2 FOREIGN KEY (numerator_unit_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT fpk_drug_strength_unit_3 FOREIGN KEY (denominator_unit_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.cohort_definition ADD CONSTRAINT fpk_cohort_definition_concept FOREIGN KEY (definition_type_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.cohort_definition ADD CONSTRAINT fpk_cohort_subject_concept FOREIGN KEY (subject_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.attribute_definition ADD CONSTRAINT fpk_attribute_type_concept FOREIGN KEY (attribute_type_concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_synonym ADD CONSTRAINT uq_concept_synonym UNIQUE (concept_id, concept_synonym_name, language_concept_id);

ALTER TABLE vocabulary.concept_synonym ADD CONSTRAINT fpk_concept_synonym_concept FOREIGN KEY (concept_id)  REFERENCES vocabulary.concept (concept_id);

ALTER TABLE vocabulary.concept_synonym ADD CONSTRAINT fpk_concept_synonym_language FOREIGN KEY (language_concept_id)  REFERENCES vocabulary.concept (concept_id);
