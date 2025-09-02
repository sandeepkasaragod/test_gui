// modules/medaka-1.nf
process MEDAKA_1 {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_bam
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.1.hdf", emit: hdf

	script:
		def medaka_model = params.medaka_model ?: 'r941_min_fast_g303'
		def threads      = (params.threads ?: 5) as int

		if( !input_bam.exists() )
			exit 1, "MEDAKA_1: Input BAM not found: ${input_bam}"

		"""
		set -euo pipefail
		[ -s "${input_bam}.bai" ] || samtools index "${input_bam}"

		medaka consensus \
			--model ${medaka_model} \
			--threads ${threads} \
			--chunk_len 800 \
			--chunk_ovlp 400 \
			--RG 1 "${input_bam}" \
			"${sampleId}.1.hdf"
		"""
}

