// modules/bcftools_consensus.nf
process BCFTOOLS_CONSENSUS {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path preconsensus_fa
		path pass_vcf
		path coverage_mask
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.consensus.fasta", emit: consensus_fa

	script:
		if( !preconsensus_fa.exists() ) exit 1, "BCFTOOLS_CONSENSUS: Preconsensus FASTA not found: ${preconsensus_fa}"
		if( !pass_vcf.exists() )        exit 1, "BCFTOOLS_CONSENSUS: PASS VCF not found: ${pass_vcf}"
		if( !coverage_mask.exists() )   exit 1, "BCFTOOLS_CONSENSUS: Coverage mask not found: ${coverage_mask}"

		"""
		set -euo pipefail

		if [[ "${pass_vcf}" == *.vcf.gz ]]; then
			ln -sf "${pass_vcf}" "${sampleId}.pass.vcf.gz"
			if [[ -f "${pass_vcf}.tbi" ]]; then
				ln -sf "${pass_vcf}.tbi" "${sampleId}.pass.vcf.gz.tbi"
			else
				tabix -p vcf "${sampleId}.pass.vcf.gz"
			fi
		else
			bgzip -fc "${pass_vcf}" > "${sampleId}.pass.vcf.gz"
			tabix -p vcf "${sampleId}.pass.vcf.gz"
		fi

		if [[ ! -f "${preconsensus_fa}.fai" ]]; then
			samtools faidx "${preconsensus_fa}"
		fi

		bcftools consensus \
			-f "${preconsensus_fa}" \
			-m "${coverage_mask}" \
			"${sampleId}.pass.vcf.gz" \
			-o "${sampleId}.consensus.fasta"
		"""
}

