#!/usr/bin/env nextflow
/*
========================================================================================
                         nf-salmon
========================================================================================

----------------------------------------------------------------------------------------
*/



/*
 * SET UP CONFIGURATION VARIABLES
 */



/*
 * Create a channel for input read files
 */

Channel
        .fromFilePairs( params.reads, size: 2 )
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nNB: Path requires at least one * wildcard!\nIf this is single-end data, please specify --singleEnd on the command line." }
        .into { read_files_salmon }


transcriptome_file = file(params.transcriptome)

/**
* STEP 1 - Build Index
*/
process index {
    tag "transcriptome.simpleName"
    publishDir "${params.outdir}/salmon", mode: 'copy'

    input:
    file transcriptome from transcriptome_file

    output:
    file 'index' into index_ch

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """
}

/*
* STEP 2 - Quantification
*/
process quant {
    tag "$pair_id"
    publishDir "${params.outdir}/salmon", mode: 'copy'

    input:
    file index from index_ch
    set pair_id, file(reads) from read_files_salmon

    output:
    file(pair_id) into quant_ch

    script:
    """
    salmon quant --threads $task.cpus  --libType A --validateMappings  -i $index -1 ${reads[0]} -2 ${reads[1]} -o $pair_id
    """
}

/*
 * Completion e-mail notification
 */
workflow.onComplete {
 log.info "Pipeline Complete"
}
