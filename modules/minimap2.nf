// modules/minimap2.nf
process MINIMAP2 {

  tag { sampleId }

  publishDir "${params.out_dir}/medaka", mode: 'copy', overwrite: true

  input:
    //path input_dir
    //tuple val(sampleId), val(item), val(scheme), val(version)
		path input_dir                                   // staged dir with FASTQs
    path reference                                   // staged reference FASTA
    tuple val(sampleId), val(item), val(scheme), val(version)

  output:
    path "${sampleId}.sorted.bam",     emit: sorted_bam
    path "${sampleId}.sorted.bam.bai", emit: sorted_bai

  script:
    """
    set -euo pipefail

    minimap2 -a -x map-ont -t ${params.threads} \
			"${reference}"	\
			"${input_dir}"	\
    | samtools view -bS -F 4 - \
    | samtools sort -o "${sampleId}.sorted.bam"

    samtools index "${sampleId}.sorted.bam"
    """
}

//"${reference}" "${reads}"
