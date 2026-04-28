# Bio-Science Problem-First Consolidation

- Generated At: `2026-04-28T10:30:49.670975+00:00`
- Current Bio-Science Skills: 26
- Target Route Authorities: 10
- Target Stage Assistants: 16
- Manual Review: 0
- Merge/Delete After Migration: 0

## Route Authorities

| skill_id | primary_problem_id | current_role | overlap_with | rationale |
| --- | --- | --- | --- | --- |
| biopython | sequence_io_entrez | route_authority | gget; pysam; database assistants | Biopython is broad and useful, but negative routing boundaries must stop it from swallowing single-cell, DESeq2, BAM/VCF, ESM, COBRApy, and flow cytometry prompts. |
| gget | gene_symbol_lookup | route_authority | biopython; bioservices; ensembl-database; gene-database | Quick lookup is a separate user intent from full single-cell or differential-expression workflows. |
| pydeseq2 | bulk_rnaseq_differential_expression | route_authority | scanpy; statistical-analysis | Bulk RNA-seq differential expression must not be absorbed by scanpy or biopython. |
| pysam | alignment_variant_files | route_authority | biopython; tiledbvcf | Alignment and variant files are concrete coding/research tasks with a dedicated Python owner. |
| scanpy | single_cell_rnaseq | route_authority | anndata; scvi-tools; cellxgene-census; pydeseq2 | Single-cell RNA-seq is a distinct high-value user problem and scanpy is the clearest owner. |
| arboreto | gene_regulatory_networks | route_authority | scanpy; geniml | Gene regulatory network inference is distinct from ordinary single-cell clustering. |
| cobrapy | metabolic_flux_modeling | route_authority | kegg-database; reactome-database; bioservices | Metabolic flux modeling is a problem owner, not a generic pathway lookup. |
| esm | protein_language_models | route_authority | alphafold-database; pdb-database; string-database | Protein embedding tasks are bio-ML tasks and should not be routed to generic sequence handling. |
| flowio | flow_cytometry_fcs_io | route_authority | anndata | FCS/flow cytometry file IO is a specific task that should not fall back to biopython. |
| geniml | genomic_ml_embeddings | route_authority | esm; data-ml | Genome embeddings are a bio-specific ML surface and need a precise owner. |

## Stage Assistants

| skill_id | primary_problem_id | target_owner | unique_assets | rationale |
| --- | --- | --- | --- | --- |
| alphafold-database | protein_structure_evidence | esm | scripts=0; references=1; assets=0 | Structure evidence supports protein workflows but does not own the main task. |
| anndata | single_cell_data_container | scanpy | scripts=0; references=5; assets=0 | AnnData is a data structure layer used inside single-cell workflows. |
| bioservices | cross_database_aggregation | database-assistant | scripts=4; references=3; assets=0 | Cross-service lookup is valuable but must not override a more specific workflow owner. |
| cellxgene-census | single_cell_reference_evidence | scanpy | scripts=0; references=2; assets=0 | Cellxgene Census supports single-cell reference lookup inside scanpy workflows. |
| clinvar-database | variant_clinical_evidence | pysam | scripts=0; references=3; assets=0 | ClinVar lookup is evidence retrieval inside a variant interpretation workflow. |
| cosmic-database | cancer_variant_evidence | pysam | scripts=1; references=1; assets=0 | COSMIC is supporting evidence for cancer variant work. |
| deeptools | genomics_track_processing | pysam | scripts=2; references=4; assets=1 | deepTools is a genomics processing helper with a narrower route surface than pysam. |
| ensembl-database | ensembl_annotation_evidence | gget | scripts=1; references=1; assets=0 | Ensembl lookup should support gget and sequence workflows. |
| gene-database | gene_annotation_evidence | gget | scripts=3; references=2; assets=0 | Gene lookup supports annotation but should not own whole workflows. |
| gwas-database | gwas_trait_evidence | gget | scripts=0; references=1; assets=0 | GWAS evidence is supporting context for genetics workflows. |
| kegg-database | pathway_metabolism_evidence | cobrapy | scripts=1; references=1; assets=0 | KEGG is useful evidence for pathway and metabolism workflows. |
| opentargets-database | target_disease_evidence | gget | scripts=1; references=3; assets=0 | OpenTargets supports target evidence, not the main computational workflow. |
| pdb-database | protein_structure_evidence | esm | scripts=0; references=1; assets=0 | PDB lookup supports structural interpretation but is not the primary route for protein embeddings. |
| reactome-database | pathway_evidence | cobrapy | scripts=1; references=1; assets=0 | Reactome supports pathway interpretation inside larger workflows. |
| scvi-tools | single_cell_latent_models | scanpy | scripts=0; references=8; assets=0 | scVI is useful inside single-cell workflows but should not absorb broad single-cell prompts in the first split. |
| string-database | protein_interaction_evidence | esm | scripts=1; references=1; assets=0 | STRING lookup is supporting evidence for protein workflows. |

## Manual Review

- none

## Merge/Delete After Migration

- none
