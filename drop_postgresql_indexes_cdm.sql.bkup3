



ALTER TABLE concept DROP CONSTRAINT xpk_concept CASCADE;
ALTER TABLE vocabulary DROP CONSTRAINT xpk_vocabulary CASCADE;
ALTER TABLE domain DROP CONSTRAINT xpk_domain CASCADE;
ALTER TABLE concept_class DROP CONSTRAINT xpk_concept_class CASCADE;
ALTER TABLE concept_relationship DROP CONSTRAINT xpk_concept_relationship CASCADE;
ALTER TABLE relationship DROP CONSTRAINT xpk_relationship CASCADE;
ALTER TABLE concept_ancestor DROP CONSTRAINT xpk_concept_ancestor CASCADE;
ALTER TABLE source_to_concept_map DROP CONSTRAINT xpk_source_to_concept_map CASCADE;
ALTER TABLE drug_strength DROP CONSTRAINT xpk_drug_strength CASCADE;
ALTER TABLE cohort_definition DROP CONSTRAINT xpk_cohort_definition CASCADE;
ALTER TABLE attribute_definition DROP CONSTRAINT xpk_attribute_definition CASCADE;

ALTER TABLE person DROP CONSTRAINT xpk_person CASCADE;
ALTER TABLE observation_period DROP CONSTRAINT xpk_observation_period CASCADE;
ALTER TABLE specimen DROP CONSTRAINT xpk_specimen CASCADE;
ALTER TABLE death DROP CONSTRAINT xpk_death CASCADE;
ALTER TABLE visit_occurrence DROP CONSTRAINT xpk_visit_occurrence CASCADE;
ALTER TABLE visit_detail DROP CONSTRAINT xpk_visit_detail CASCADE;
ALTER TABLE procedure_occurrence DROP CONSTRAINT xpk_procedure_occurrence CASCADE;
ALTER TABLE drug_exposure DROP CONSTRAINT xpk_drug_exposure CASCADE;
ALTER TABLE device_exposure DROP CONSTRAINT xpk_device_exposure CASCADE;
ALTER TABLE condition_occurrence DROP CONSTRAINT xpk_condition_occurrence CASCADE;
ALTER TABLE measurement DROP CONSTRAINT xpk_measurement CASCADE;
ALTER TABLE note DROP CONSTRAINT xpk_note CASCADE;
ALTER TABLE note_nlp DROP CONSTRAINT xpk_note_nlp CASCADE;
ALTER TABLE observation  DROP CONSTRAINT xpk_observation CASCADE;

ALTER TABLE location DROP CONSTRAINT xpk_location CASCADE;
ALTER TABLE care_site DROP CONSTRAINT xpk_care_site CASCADE;
ALTER TABLE provider DROP CONSTRAINT xpk_provider CASCADE;

ALTER TABLE payer_plan_period DROP CONSTRAINT xpk_payer_plan_period CASCADE;
ALTER TABLE cost DROP CONSTRAINT xpk_visit_cost CASCADE;

ALTER TABLE cohort DROP CONSTRAINT xpk_cohort CASCADE;
ALTER TABLE cohort_attribute DROP CONSTRAINT xpk_cohort_attribute CASCADE;
ALTER TABLE drug_era DROP CONSTRAINT xpk_drug_era CASCADE;
ALTER TABLE dose_era  DROP CONSTRAINT xpk_dose_era CASCADE;
ALTER TABLE condition_era DROP CONSTRAINT xpk_condition_era CASCADE;

DROP INDEX idx_concept_concept_id  CASCADE;
DROP INDEX idx_concept_code CASCADE;
DROP INDEX idx_concept_vocabluary_id CASCADE;
DROP INDEX idx_concept_domain_id CASCADE;
DROP INDEX idx_concept_class_id CASCADE;

DROP INDEX idx_vocabulary_vocabulary_id  CASCADE;

DROP INDEX idx_domain_domain_id  CASCADE;

DROP INDEX idx_concept_class_class_id  CASCADE;

DROP INDEX idx_concept_relationship_id_1 CASCADE;
DROP INDEX idx_concept_relationship_id_2 CASCADE;
DROP INDEX idx_concept_relationship_id_3 CASCADE;

DROP INDEX idx_relationship_rel_id  CASCADE;

DROP INDEX idx_concept_synonym_id  CASCADE;

DROP INDEX idx_concept_ancestor_id_1  CASCADE;
DROP INDEX idx_concept_ancestor_id_2 CASCADE;

DROP INDEX idx_source_to_concept_map_id_3  CASCADE;
DROP INDEX idx_source_to_concept_map_id_1 CASCADE;
DROP INDEX idx_source_to_concept_map_id_2 CASCADE;
DROP INDEX idx_source_to_concept_map_code CASCADE;

DROP INDEX idx_drug_strength_id_1  CASCADE;
DROP INDEX idx_drug_strength_id_2 CASCADE;

DROP INDEX idx_cohort_definition_id  CASCADE;

DROP INDEX idx_attribute_definition_id  CASCADE;



DROP INDEX idx_person_id  CASCADE;

DROP INDEX idx_observation_period_id  CASCADE;

DROP INDEX idx_specimen_person_id  CASCADE;
DROP INDEX idx_specimen_concept_id CASCADE;

DROP INDEX idx_death_person_id  CASCADE;

DROP INDEX idx_visit_person_id  CASCADE;
DROP INDEX idx_visit_concept_id CASCADE;

DROP INDEX idx_visit_detail_person_id  CASCADE;
DROP INDEX idx_visit_detail_concept_id CASCADE;

DROP INDEX idx_procedure_person_id  CASCADE;
DROP INDEX idx_procedure_concept_id CASCADE;
DROP INDEX idx_procedure_visit_id CASCADE;

DROP INDEX idx_drug_person_id  CASCADE;
DROP INDEX idx_drug_concept_id CASCADE;
DROP INDEX idx_drug_visit_id CASCADE;

DROP INDEX idx_device_person_id  CASCADE;
DROP INDEX idx_device_concept_id CASCADE;
DROP INDEX idx_device_visit_id CASCADE;

DROP INDEX idx_condition_person_id  CASCADE;
DROP INDEX idx_condition_concept_id CASCADE;
DROP INDEX idx_condition_visit_id CASCADE;

DROP INDEX idx_measurement_person_id  CASCADE;
DROP INDEX idx_measurement_concept_id CASCADE;
DROP INDEX idx_measurement_visit_id CASCADE;

DROP INDEX idx_note_person_id  CASCADE;
DROP INDEX idx_note_concept_id CASCADE;
DROP INDEX idx_note_visit_id CASCADE;

DROP INDEX idx_note_nlp_note_id  CASCADE;
DROP INDEX idx_note_nlp_concept_id CASCADE;

DROP INDEX idx_observation_person_id  CASCADE;
DROP INDEX idx_observation_concept_id CASCADE;
DROP INDEX idx_observation_visit_id CASCADE;

DROP INDEX idx_fact_relationship_id_1 CASCADE;
DROP INDEX idx_fact_relationship_id_2 CASCADE;
DROP INDEX idx_fact_relationship_id_3 CASCADE;


DROP INDEX idx_period_person_id  CASCADE;


DROP INDEX idx_cohort_subject_id CASCADE;
DROP INDEX idx_cohort_c_definition_id CASCADE;

DROP INDEX idx_ca_subject_id CASCADE;
DROP INDEX idx_ca_definition_id CASCADE;

DROP INDEX idx_drug_era_person_id  CASCADE;
DROP INDEX idx_drug_era_concept_id CASCADE;

DROP INDEX idx_dose_era_person_id  CASCADE;
DROP INDEX idx_dose_era_concept_id CASCADE;

DROP INDEX idx_condition_era_person_id  CASCADE;
DROP INDEX idx_condition_era_concept_id CASCADE;

