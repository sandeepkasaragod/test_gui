// modules/make_depth_mask.nf
process MAKE_DEPTH_MASK {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_vcf
		path input_bam
		path reference
		path make_depth_mask_script
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.coverage_mask.txt", emit: coverage_mask

	// errorStrategy 'terminate'   // switch to 'ignore' only if you really want to continue on failure

	script:
		//def make_depth_mask = file("${projectDir}/scripts/make_depth_mask.py")
		//def reference       = file("${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta")
		//def mask_depth      = (params.mask_depth ?: 20) as int

		if( !make_depth_mask_script.exists() )
			exit 1, "MAKE_DEPTH_MASK: Script not found: ${make_depth_mask_script}"
		if( !reference.exists() )
			exit 1, "MAKE_DEPTH_MASK: Reference not found: ${reference}"
		if( !input_bam.exists() )
			exit 1, "MAKE_DEPTH_MASK: Input BAM not found: ${input_bam}"
		if( !input_vcf.exists() )
			log.warn "MAKE_DEPTH_MASK: PASS VCF not found (continuing without it): ${input_vcf}"

	"""
	set -euo pipefail
	[ -s "${input_bam}.bai" ] || samtools index "${input_bam}"

	python "${make_depth_mask_script}" \
		--depth ${params.mask_depth} \
		--store-rg-depths \
		"${reference}" \
		"${input_bam}" \
		"${sampleId}.coverage_mask.txt"
	"""
}

