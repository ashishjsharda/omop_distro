/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
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



postgresql script to create the required indexes within OMOP common data model, version 5.3

last revised: 14-November-2017

author:  Patrick Ryan, Clair Blacketer

description:  These primary keys and indices are considered a minimal requirement to ensure adequate performance of analyses.

*************************/


/************************
*************************
*************************
*************************

Primary key constraints

*************************
*************************
*************************
************************/



/************************

Standardized vocabulary

************************/



ALTER TABLE vocabulary.concept ADD CONSTRAINT xpk_concept PRIMARY KEY (concept_id);

ALTER TABLE vocabulary.vocabulary ADD CONSTRAINT xpk_vocabulary PRIMARY KEY (vocabulary_id);

ALTER TABLE vocabulary.domain ADD CONSTRAINT xpk_domain PRIMARY KEY (domain_id);

ALTER TABLE vocabulary.concept_class ADD CONSTRAINT xpk_concept_class PRIMARY KEY (concept_class_id);

ALTER TABLE vocabulary.concept_relationship ADD CONSTRAINT xpk_concept_relationship PRIMARY KEY (concept_id_1,concept_id_2,relationship_id);

ALTER TABLE vocabulary.relationship ADD CONSTRAINT xpk_relationship PRIMARY KEY (relationship_id);

ALTER TABLE vocabulary.concept_ancestor ADD CONSTRAINT xpk_concept_ancestor PRIMARY KEY (ancestor_concept_id,descendant_concept_id);

ALTER TABLE vocabulary.source_to_concept_map ADD CONSTRAINT xpk_source_to_concept_map PRIMARY KEY (source_vocabulary_id,target_concept_id,source_code,valid_end_date);

ALTER TABLE vocabulary.drug_strength ADD CONSTRAINT xpk_drug_strength PRIMARY KEY (drug_concept_id, ingredient_concept_id);

ALTER TABLE vocabulary.cohort_definition ADD CONSTRAINT xpk_cohort_definition PRIMARY KEY (cohort_definition_id);

ALTER TABLE vocabulary.attribute_definition ADD CONSTRAINT xpk_attribute_definition PRIMARY KEY (attribute_definition_id);



/************************

Standardized vocabulary

************************/

CREATE UNIQUE INDEX idx_concept_concept_id  ON vocabulary.concept  (concept_id ASC);
CLUSTER vocabulary.concept  USING idx_concept_concept_id ;
CREATE INDEX idx_concept_code ON vocabulary.concept (concept_code ASC);
CREATE INDEX idx_concept_vocabluary_id ON vocabulary.concept (vocabulary_id ASC);
CREATE INDEX idx_concept_domain_id ON vocabulary.concept (domain_id ASC);
CREATE INDEX idx_concept_class_id ON vocabulary.concept (concept_class_id ASC);

CREATE UNIQUE INDEX idx_vocabulary_vocabulary_id  ON vocabulary.vocabulary  (vocabulary_id ASC);
CLUSTER vocabulary.vocabulary  USING idx_vocabulary_vocabulary_id ;

CREATE UNIQUE INDEX idx_domain_domain_id  ON vocabulary.domain  (domain_id ASC);
CLUSTER vocabulary.domain  USING idx_domain_domain_id ;

CREATE UNIQUE INDEX idx_concept_class_class_id  ON vocabulary.concept_class  (concept_class_id ASC);
CLUSTER vocabulary.concept_class  USING idx_concept_class_class_id ;

CREATE INDEX idx_concept_relationship_id_1 ON vocabulary.concept_relationship (concept_id_1 ASC);
CREATE INDEX idx_concept_relationship_id_2 ON vocabulary.concept_relationship (concept_id_2 ASC);
CREATE INDEX idx_concept_relationship_id_3 ON vocabulary.concept_relationship (relationship_id ASC);

CREATE UNIQUE INDEX idx_relationship_rel_id  ON vocabulary.relationship  (relationship_id ASC);
CLUSTER vocabulary.relationship  USING idx_relationship_rel_id ;

CREATE INDEX idx_concept_ancestor_id_1  ON vocabulary.concept_ancestor  (ancestor_concept_id ASC);
CLUSTER vocabulary.concept_ancestor  USING idx_concept_ancestor_id_1 ;
CREATE INDEX idx_concept_ancestor_id_2 ON vocabulary.concept_ancestor (descendant_concept_id ASC);

CREATE INDEX idx_source_to_concept_map_id_3  ON vocabulary.source_to_concept_map  (target_concept_id ASC);
CLUSTER vocabulary.source_to_concept_map  USING idx_source_to_concept_map_id_3 ;
CREATE INDEX idx_source_to_concept_map_id_1 ON vocabulary.source_to_concept_map (source_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_id_2 ON vocabulary.source_to_concept_map (target_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_code ON vocabulary.source_to_concept_map (source_code ASC);

CREATE INDEX idx_drug_strength_id_1  ON vocabulary.drug_strength  (drug_concept_id ASC);
CLUSTER vocabulary.drug_strength  USING idx_drug_strength_id_1 ;
CREATE INDEX idx_drug_strength_id_2 ON vocabulary.drug_strength (ingredient_concept_id ASC);

CREATE INDEX idx_cohort_definition_id  ON vocabulary.cohort_definition  (cohort_definition_id ASC);
CLUSTER vocabulary.cohort_definition  USING idx_cohort_definition_id ;

CREATE INDEX idx_attribute_definition_id  ON vocabulary.attribute_definition  (attribute_definition_id ASC);
CLUSTER vocabulary.attribute_definition  USING idx_attribute_definition_id ;

CREATE INDEX idx_concept_synonym_id  ON vocabulary.concept_synonym  (concept_id ASC);
CLUSTER vocabulary.concept_synonym  USING idx_concept_synonym_id ;

