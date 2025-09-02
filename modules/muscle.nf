// modules/muscle.nf
process MUSCLE {

	tag { sampleId }

	maxForks 1

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path muscle_in_fa
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		path "${sampleId}.muscle.out.fasta", emit: muscle_op_fasta

	// errorStrategy 'terminate'

	script:
		if( !muscle_in_fa.exists() )
			exit 1, "MUSCLE: Input FASTA not found: ${muscle_in_fa}"

	"""
		set -euo pipefail

		version=\$(muscle -version 2>&1 | head -n 1 || true)

		if echo "\$version" | grep -q "3.8"; then
			echo "MUSCLE: Using v3 syntax"
			muscle -in "${muscle_in_fa}" \
				-out "${sampleId}.muscle.out.fasta"
		else
			echo "MUSCLE: Using v5 syntax"
			muscle -align "${muscle_in_fa}" \
			-output "${sampleId}.muscle.out.fasta"
		fi
	"""
}

