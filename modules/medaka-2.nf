// modules/medaka-2.nf
process MEDAKA_2 {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_bam
		path input_hdf
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.2.hdf", emit: hdf

  // errorStrategy 'terminate'   // prefer to fail loudly; flip to 'ignore' if you must

	script:
		def medaka_model = params.medaka_model ?: 'r941_min_fast_g303'
		def threads      = (params.threads ?: 5) as int

		if( !input_bam.exists() )
			exit 1, "MEDAKA_2: Input BAM not found: ${input_bam}"
		if( !input_hdf.exists() )
			exit 1, "MEDAKA_2: Input HDF (from MEDAKA_1) not found: ${input_hdf}"

		"""
		set -euo pipefail
		[ -s "${input_bam}.bai" ] || samtools index "${input_bam}"

		medaka consensus \
			--model ${medaka_model} \
			--threads ${threads} \
			--chunk_len 800 \
			--chunk_ovlp 400 \
			--RG 2 "${input_bam}" \
			"${sampleId}.2.hdf"
		"""
}

