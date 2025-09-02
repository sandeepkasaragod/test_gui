// modules/report.nf
process REPORT {

	tag { "report" }

	publishDir "${params.out_dir}", mode: 'copy'

	input:
	path summary_file
	path medaka_dir
	path summary_report_dir
	path report_script

	output:
		path "combined_summary_report.html", emit: report

	script:
		//def report_py  = file("${projectDir}/scripts/report.py")
		//def align_dir  = file("${projectDir}/${params.out_dir}/medaka")

		if( !report_script.exists() ) exit 1, "REPORT: Script not found: ${report_script}"

		"""
		set -euo pipefail

		python "${report_script}" \
			--alignreport_dir "${medaka_dir}" \
			--summary_stats_file "${summary_file}" \
			--output_dir "."

		if [ ! -f "combined_summary_report.html" ]; then
			first_html=\$(ls -1 *.html 2>/dev/null | head -n1 || true)
			if [ -n "\${first_html}" ]; then
				cp "\${first_html}" "combined_summary_report.html"
			else
				echo "REPORT: No HTML produced by report script" >&2
				exit 1
			fi
		fi
	"""
}

