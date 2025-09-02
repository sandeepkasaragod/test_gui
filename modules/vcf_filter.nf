// modules/vcf_filter.nf
process VCF_FILTER {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_vcf
		path vcf_filter_script
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.pass.vcf", emit: pass_vcf
		path "${sampleId}.fail.vcf", emit: fail_vcf
		path "${sampleId}.pass.vcf.gz", emit: pass_vcf_gz
	// errorStrategy 'terminate'   // prefer to fail loudly; switch to 'ignore' if you must

	script:
		def vcf_filter = file("${projectDir}/scripts/vcf_filter.py")

		if( !input_vcf.exists() )
			exit 1, "VCF_FILTER: Input VCF not found: ${input_vcf}"
		if( !vcf_filter.exists() )
			exit 1, "VCF_FILTER: vcf_filter.py not found: ${vcf_filter}"

		"""
		set -euo pipefail

		python "${vcf_filter_script}" --medaka \
			"${input_vcf}" \
			"${sampleId}.pass.vcf" \
			"${sampleId}.fail.vcf"

		bgzip -fc "${sampleId}.pass.vcf" > "${sampleId}.pass.vcf.gz"
		tabix -p vcf "${sampleId}.pass.vcf.gz"
    """
}

