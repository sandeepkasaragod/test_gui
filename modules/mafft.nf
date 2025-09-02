// modules/mafft.nf
process MAFFT {

	tag { "mafft_alignment" }

	publishDir "${params.out_dir}/mafft", mode: 'copy'

	input:
		path concat_fa

	output:
		path "genome-aln.fasta", emit: mafft_fa

	// errorStrategy 'terminate'

	script:
		//def threads = (params.threads ?: 4) as int
		if( !concat_fa.exists() )
			exit 1, "MAFFT: Input concatenated FASTA not found: ${concat_fa}"

		"""
		set -euo pipefail
		mafft --thread ${params.threads} "${concat_fa}" > "genome-aln.fasta"
    """
}

