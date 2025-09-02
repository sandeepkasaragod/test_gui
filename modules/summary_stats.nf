// modules/summary_stats.nf
process SUMMARY_STATS {

	tag { "summary_stats" }

	publishDir "${params.out_dir}/summary_stats", mode: 'copy'

	input:
		path trigger_file
		path medaka_dir
		path summary_stats_script

	output:
		path "summary_stats.txt", emit: summary

	script:
    //def summary_py = file("${projectDir}/scripts/summary_stats.py")
    //def medaka_dir = file("${projectDir}/${params.out_dir}/medaka")

    if( !summary_stats_script.exists() ) exit 1, "SUMMARY_STATS: Script not found: ${summary_stats_script}"

    """
    set -euo pipefail
    python "${summary_stats_script}" \
      -i "${medaka_dir}" \
      -o "summary_stats.txt"
    """
}

