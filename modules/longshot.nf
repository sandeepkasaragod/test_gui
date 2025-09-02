// modules/longshot.nf
process LONGSHOT {

	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path input_vcf          // potential variants VCF (merged)
		path input_bam          // primer-trimmed BAM
		path reference
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.longshot.merged.vcf", emit: vcf
		//path "${sampleId}.potential.vcf.gz", emit: potential_vcf

	script:
		//def reference = file("${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta")
		if( !input_vcf.exists() )  exit 1, "LONGSHOT: Input VCF not found: ${input_vcf}"
		if( !input_bam.exists() )  exit 1, "LONGSHOT: Input BAM not found: ${input_bam}"
		if( !reference.exists() )  exit 1, "LONGSHOT: Reference not found: ${reference}"

	"""
	set -euo pipefail

	if [ ! -f "${reference}.fai" ]; then
		echo "Indexing reference with samtools faidx"
		samtools faidx "${reference}"
	fi

	if [ ! -f "${input_bam}.bai" ] && [ ! -f "${input_bam}.bai" ]; then
		echo "Indexing BAM"
		samtools index "${input_bam}"
	fi

	longshot -P 0 -F -A --no_haps \
		--bam "${input_bam}" \
		--ref "${reference}" \
		--out "${sampleId}.longshot.merged.vcf"	\
	"""
}

//--potential_variants "${sampleId}.potential.vcf.gz"

