/*********************************************************************************
# Copyright 2017-11 Observational Health Data Sciences and Informatics
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

 ####### #     # ####### ######      #####  ######  #     #           #######      #####
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #           #     #
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #                 #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######       #####
 #     # #     # #     # #          #       #     # #     #    #    #       # ###       #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ### #     #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###  #####


postgresql script to create OMOP common data model version 5.3

last revised: 14-June-2018

Authors:  Patrick Ryan, Christian Reich, Clair Blacketer


*************************/


/************************

Standardized vocabulary

************************/


CREATE TABLE vocabulary.concept (
  concept_id			    INTEGER			  NOT NULL ,
  concept_name			  VARCHAR(255)	NOT NULL ,
  domain_id				    VARCHAR(20)		NOT NULL ,
  vocabulary_id			  VARCHAR(20)		NOT NULL ,
  concept_class_id		VARCHAR(20)		NOT NULL ,
  standard_concept		VARCHAR(1)		NULL ,
  concept_code			  VARCHAR(50)		NOT NULL ,
  valid_start_date		DATE			    NOT NULL ,
  valid_end_date		  DATE			    NOT NULL ,
  invalid_reason		  VARCHAR(1)		NULL
)
;


CREATE TABLE vocabulary.vocabulary (
  vocabulary_id			    VARCHAR(20)		NOT NULL,
  vocabulary_name		    VARCHAR(255)	NOT NULL,
  vocabulary_reference	VARCHAR(255)	NOT NULL,
  vocabulary_version	  VARCHAR(255)	NOT NULL,
  vocabulary_concept_id	INTEGER			  NOT NULL
)
;


CREATE TABLE vocabulary.domain (
  domain_id			    VARCHAR(20)		NOT NULL,
  domain_name		    VARCHAR(255)	NOT NULL,
  domain_concept_id	INTEGER			  NOT NULL
)
;


CREATE TABLE vocabulary.concept_class (
  concept_class_id			    VARCHAR(20)		NOT NULL,
  concept_class_name		    VARCHAR(255)	NOT NULL,
  concept_class_concept_id	INTEGER			  NOT NULL
)
;


CREATE TABLE vocabulary.concept_relationship (
  concept_id_1			INTEGER			NOT NULL,
  concept_id_2			INTEGER			NOT NULL,
  relationship_id		VARCHAR(20)	NOT NULL,
  valid_start_date	DATE			  NOT NULL,
  valid_end_date		DATE			  NOT NULL,
  invalid_reason		VARCHAR(1)	NULL
  )
;


CREATE TABLE vocabulary.relationship (
  relationship_id			    VARCHAR(20)		NOT NULL,
  relationship_name			  VARCHAR(255)	NOT NULL,
  is_hierarchical			    VARCHAR(1)		NOT NULL,
  defines_ancestry			  VARCHAR(1)		NOT NULL,
  reverse_relationship_id	VARCHAR(20)		NOT NULL,
  relationship_concept_id	INTEGER			  NOT NULL
)
;



CREATE TABLE vocabulary.concept_ancestor (
  ancestor_concept_id		    INTEGER		NOT NULL,
  descendant_concept_id		  INTEGER		NOT NULL,
  min_levels_of_separation	INTEGER		NOT NULL,
  max_levels_of_separation	INTEGER		NOT NULL
)
;


CREATE TABLE vocabulary.source_to_concept_map (
  source_code				      VARCHAR(50)		NOT NULL,
  source_concept_id			  INTEGER			  NOT NULL,
  source_vocabulary_id		VARCHAR(20)		NOT NULL,
  source_code_description	VARCHAR(255)	NULL,
  target_concept_id			  INTEGER			  NOT NULL,
  target_vocabulary_id		VARCHAR(20)		NOT NULL,
  valid_start_date			  DATE			    NOT NULL,
  valid_end_date			    DATE			    NOT NULL,
  invalid_reason			    VARCHAR(1)		NULL
)
;




CREATE TABLE vocabulary.drug_strength (
  drug_concept_id				      INTEGER		  NOT NULL,
  ingredient_concept_id			  INTEGER		  NOT NULL,
  amount_value					      NUMERIC		    NULL,
  amount_unit_concept_id		  INTEGER		  NULL,
  numerator_value				      NUMERIC		    NULL,
  numerator_unit_concept_id		INTEGER		  NULL,
  denominator_value				    NUMERIC		    NULL,
  denominator_unit_concept_id	INTEGER		  NULL,
  box_size						        INTEGER		  NULL,
  valid_start_date				    DATE		    NOT NULL,
  valid_end_date				      DATE		    NOT NULL,
  invalid_reason				      VARCHAR(1)  NULL
)
;


CREATE TABLE vocabulary.cohort_definition (
  cohort_definition_id				    INTEGER			  NOT NULL,
  cohort_definition_name			    VARCHAR(255)	NOT NULL,
  cohort_definition_description		TEXT	NULL,
  definition_type_concept_id		  INTEGER			  NOT NULL,
  cohort_definition_syntax			  TEXT	NULL,
  subject_concept_id				      INTEGER			  NOT NULL,
  cohort_initiation_date			    DATE			    NULL
)
;


CREATE TABLE vocabulary.attribute_definition (
  attribute_definition_id		  INTEGER			  NOT NULL,
  attribute_name				      VARCHAR(255)	NOT NULL,
  attribute_description			  TEXT	NULL,
  attribute_type_concept_id		INTEGER			  NOT NULL,
  attribute_syntax				    TEXT	NULL
)
;

CREATE TABLE vocabulary.concept_synonym (
  concept_id			      INTEGER			  NOT NULL,
  concept_synonym_name	VARCHAR(1000)	NOT NULL,
  language_concept_id	  INTEGER			  NOT NULL
)
;

