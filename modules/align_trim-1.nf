// modules/align_trim-1.nf
process ALIGN_TRIM_1 {

  tag { sampleId }

  // Copy outputs into results/medaka (created automatically)
  publishDir "${params.out_dir}/medaka", mode: 'copy'

  input:
    path input_bam
		path align_trim
		path bed
    tuple val(sampleId), val(item), val(scheme), val(version)

  output:
    path "${sampleId}.alignreport.txt",         emit: align_report
    path "${sampleId}.trimmed.rg.sorted.bam",   emit: trimmed_bam
    path "${sampleId}.trimmed.rg.sorted.bam.bai", emit: trimmed_bai

  errorStrategy 'terminate'   // (use 'ignore' if you must, but it's better to fail loudly)

  script:
    // Resolve all paths INSIDE the process
    //def bed         = file("${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed")
    //def align_trim  = file("${projectDir}/scripts/align_trim.py")
    //def normalise   = params.medaka_normalise ?: 200

    if( !bed.exists() )
      exit 1, "ALIGN_TRIM_1: Scheme BED not found: ${bed}"
    if( !align_trim.exists() )
      exit 1, "ALIGN_TRIM_1: align_trim.py not found: ${align_trim}"

    """
    set -euo pipefail

    # Generate align report and trimmed BAM
    python "${align_trim}" --normalise ${params.medaka_normalise} "${bed}" --start \
      --report "${sampleId}.alignreport.txt" \
      < "${input_bam}" \
      2> "${sampleId}.alignreport.err" \
    | samtools sort -T "${sampleId}" -o "${sampleId}.trimmed.rg.sorted.bam"

    samtools index "${sampleId}.trimmed.rg.sorted.bam"
    """
}

