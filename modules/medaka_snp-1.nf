// modules/medaka-snp-1.nf
process MEDAKA_SNP_1 {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path output_from_medaka_2
		path input_hdf
		path reference
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.1.vcf", emit: vcf

	// errorStrategy 'terminate'   // prefer to fail loudly; switch to 'ignore' if you must

	script:
		//def reference = file("${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta")

		if( !input_hdf.exists() )
			exit 1, "MEDAKA_SNP_1: Input HDF not found: ${input_hdf}"
		if( !reference.exists() )
			exit 1, "MEDAKA_SNP_1: Reference not found: ${reference}"

		"""
		set -euo pipefail

		medaka snp "${reference}" "${input_hdf}" "${sampleId}.1.vcf"
    """
}

