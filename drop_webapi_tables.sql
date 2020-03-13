drop table if exists analysis_generation_info;
drop sequence analysis_execution_sequence;

drop table if exists batch_job_execution;
drop table if exists batch_job_execution_context;
drop table if exists batch_job_execution_params;
drop table if exists batch_job_instance;
drop sequence  batch_job_execution_seq;
drop sequence  batch_job_seq;

drop table if exists batch_step_execution;
drop table if exists batch_step_execution_context;
drop sequence batch_step_execution_seq;

drop table if exists cc_analysis;
drop table if exists cc_cohort;
drop table if exists cc_param;
drop table if exists cc_strata;
drop table if exists cc_strata_conceptset;
drop view cc_generation;
drop sequence cc_param_sequence;
drop sequence cc_strata_conceptset_seq;
drop sequence cc_strata_seq;

drop table if exists cca;
drop table if exists cca_execution;
drop table if exists cca_execution_ext;
drop sequence cca_execution_sequence;
drop sequence cca_sequence;

drop table if exists cohort_analysis_gen_info;
drop table if exists cohort_analysis_list_xref;
drop table if exists cohort_characterization;
drop table if exists cohort_concept_map;
drop table if exists cohort_definition_details;
drop table if exists cohort_features;
drop table if exists cohort_features_analysis_ref;
drop table if exists cohort_features_dist;
drop table if exists cohort_features_ref;
drop table if exists cohort_generation_info;
drop table if exists cohort_inclusion;
drop table if exists cohort_inclusion_result;
drop table if exists cohort_inclusion_stats;
drop table if exists cohort_study;
drop table if exists cohort_summary_stats;
drop sequence cohort_characterization_seq;
drop sequence cohort_definition_sequence;
drop sequence cohort_features_analysis_ref_id_seq;
drop sequence cohort_features_dist_id_seq;
drop sequence cohort_features_id_seq;
drop sequence cohort_features_ref_id_seq;
drop sequence cohort_study_cohort_study_id_seq;

drop table if exists concept_of_interest;
drop table if exists concept_set;
drop table if exists concept_set_generation_info;
drop table if exists concept_set_item;
drop table if exists concept_set_negative_controls;
drop sequence concept_of_interest_id_seq;
drop sequence concept_set_item_sequence;
drop sequence concept_set_sequence;

drop table if exists drug_hoi_evidence;
drop table if exists drug_hoi_relationship;
drop sequence drug_hoi_evidence_sequence;

drop table if exists drug_labels;

drop table if exists ee_analysis_status;

drop table if exists estimation;
drop view estimation_analysis_generation;
drop sequence estimation_seq;

drop table if exists evidence_sources;
drop sequence evidence_sources_sequence;

drop table if exists exampleapp_widget;

drop table if exists fe_analysis;
drop sequence fe_analysis_sequence;
drop table if exists fe_analysis_conceptset;
drop sequence fe_conceptset_sequence;
drop table if exists fe_analysis_criteria;
drop sequence fe_analysis_criteria_sequence;

drop table if exists feas_study_generation_info;
drop table if exists feas_study_inclusion_stats;
drop table if exists feas_study_index_stats;
drop table if exists feas_study_result;
drop table if exists feasibility_inclusion;
drop table if exists feasibility_study;
drop sequence feasibility_study_sequence;

drop table if exists heracles_analysis;
drop table if exists heracles_heel_results;
drop table if exists heracles_results;
drop table if exists heracles_results_dist;
drop table if exists heracles_visualization_data;
drop sequence heracles_heel_results_id_seq;
drop sequence heracles_results_dist_id_seq;
drop sequence heracles_results_id_seq;
drop sequence heracles_vis_data_sequence;
drop sequence heracles_viz_data_sequence;

drop table if exists input_files;
drop sequence input_file_seq;

drop table if exists ir_analysis;
drop table if exists ir_analysis_details;
drop table if exists ir_analysis_dist;
drop table if exists ir_analysis_result;
drop table if exists ir_analysis_strata_stats;
drop table if exists ir_execution;
drop table if exists ir_strata;
drop sequence  ir_analysis_dist_id_seq;
drop sequence  ir_analysis_result_id_seq;
drop sequence  ir_analysis_sequence;
drop sequence  ir_analysis_strata_stats_id_seq;
drop sequence  ir_strata_id_seq;

drop table if exists laertes_summary;
drop sequence  laertes_summary_sequence;

drop table if exists output_files;
drop sequence output_file_seq;
drop table if exists output_file_contents;

drop table if exists pathway_analysis;
drop table if exists pathway_event_cohort;
drop table if exists pathway_target_cohort;
drop view pathway_analysis_generation;
drop sequence pathway_analysis_sequence;
drop sequence pathway_cohort_sequence;

drop table if exists penelope_laertes_uni_pivot;
drop table if exists penelope_laertes_universe;
drop sequence penelope_laertes_uni_pivot_id_seq;

drop table if exists phenotype;

drop table if exists plp;
drop sequence plp_sequence;

drop table if exists prediction;
drop view prediction_analysis_generation;
drop sequence prediction_seq;

drop table if exists schema_version;

drop table if exists sec_permission;
drop sequence sec_permission_id_seq;
drop sequence sec_permission_sequence;

drop table if exists sec_role;
drop sequence sec_role_sequence;

drop table if exists sec_role_group;
drop sequence sec_role_group_seq;

drop table if exists sec_role_permission;
drop sequence sec_role_permission_sequence;

drop table if exists sec_user;
drop sequence sec_user_sequence;

drop table if exists sec_user_role;
drop sequence sec_user_role_sequence;

drop table if exists source;
drop sequence source_sequence;

drop table if exists source_daimon;
drop sequence source_daimon_sequence;

drop table if exists user_import_job;
drop view user_import_job_history;
drop sequence user_import_job_seq;

drop table if exists user_import_job_weekday;
