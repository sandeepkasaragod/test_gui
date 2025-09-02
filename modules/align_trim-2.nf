// modules/align_trim-2.nf
process ALIGN_TRIM_2 {
	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_bam
		path align_trim
		path bed
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.alignreport2.txt",                emit: align_report
		path "${sampleId}.primertrimmed.rg.sorted.bam",     emit: primertrimmed_bam
		path "${sampleId}.primertrimmed.rg.sorted.bam.bai", emit: primertrimmed_bai

	errorStrategy 'terminate'

	script:
    // Resolve everything INSIDE the process
    //def bed        = file("${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed")
    //def align_trim = file("${projectDir}/scripts/align_trim.py")
    //def normalise  = params.medaka_normalise ?: 200

		if( !bed.exists() )
			exit 1, "ALIGN_TRIM_2: Scheme BED not found: ${bed}"
		if( !align_trim.exists() )
			exit 1, "ALIGN_TRIM_2: align_trim.py not found: ${align_trim}"
		if( !input_bam.exists() )
			exit 1, "ALIGN_TRIM_2: Input BAM not found: ${input_bam}"

		"""
		set -euo pipefail

		python "${align_trim}" \
			--normalise ${params.medaka_normalise} \
			"${bed}" \
			--report "${sampleId}.alignreport2.txt" \
			< "${input_bam}" \
			2> "${sampleId}.alignreport.err" \
			| samtools sort -T "${sampleId}" -o "${sampleId}.primertrimmed.rg.sorted.bam"

		samtools index "${sampleId}.primertrimmed.rg.sorted.bam"
    """
}

