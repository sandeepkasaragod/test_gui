
process VCF_MERGE {
	tag { sampleId }

	publishDir "${params.out_dir}/medaka", mode: 'copy'

	input:
		path vcf2
		path vcf1
		path bed
		path vcf_merge_script 
		tuple val(sampleId), val(item), val(scheme), val(version)

	output:
		//path "${sampleId}.merged.vcf",     emit: merged_vc
		path "${sampleId}.merged.vcf.gz",     emit: merged_vcf
		path "${sampleId}.merged.vcf.gz.tbi", emit: merged_tbi
		path "${sampleId}.primersitereport.txt", emit: primer_report

	//errorStrategy 'ignore'  // keep your previous behaviour if you want

	script:
	"""
	set -euo pipefail

	# Stage script from the repo into the task dir
	#MERGER="\$(basename ${file("${projectDir}/scripts/vcf_merge.py")})"

	# Sanity checks
	[ -s "${vcf1}" ] || { echo "VCF1 missing: ${vcf1}" >&2; exit 1; }
	[ -s "${vcf2}" ] || { echo "VCF2 missing: ${vcf2}" >&2; exit 1; }
	[ -s "${bed}"  ] || { echo "BED missing: ${bed}"  >&2; exit 1; }

	# Run merge; use sampleId as output prefix in the task work dir
	python "${vcf_merge_script}" \
		"${sampleId}" \
		"${bed}" \
		"2:${vcf2}" \
		"1:${vcf1}" \
		2> "${sampleId}.primersitereport.txt"

	bgzip -f "${sampleId}.merged.vcf"
	tabix -f -p vcf "${sampleId}.merged.vcf.gz"
	"""
}

// 42   bgzip -f "${sampleId}.merged.vcf"
// 43   tabix -f -p vcf "${sampleId}.merged.vcf.gz"

