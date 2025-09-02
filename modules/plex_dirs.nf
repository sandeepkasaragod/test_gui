process PLEX_DIRS {
  tag { "${sample_id}_${item}" }
  publishDir "${projectDir}/${params.fastq_dir}", mode: 'copy', overwrite: true

  input:
    val input_dir
		path script_ch
    tuple val(sample_id), val(item), val(scheme), val(version)

  output:
    path "${sample_id}_${item}${params.fq_extension}", emit: reads

  script:
    def src_dir     = file("${input_dir}/${item}")
    """
    set -euo pipefail
		python "${script_ch}" \
      --skip_quality_check \
      --min_length ${params.seq_len} \
      -d "${input_dir}/${item}" \
      -o "${sample_id}_${item}${params.fq_extension}"

    """
}
//python "${script_path}" \
//#def script_path = "${projectDir}/scripts/directory_plex.py"
