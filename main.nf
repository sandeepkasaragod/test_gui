// main.nf
nextflow.enable.dsl=2

// -----------------------------------------------------------------------------
// Project-relative includes (robust under EPI2ME instances)
// -----------------------------------------------------------------------------
def MODULES = "${projectDir}/modules"

include { GUPPY_BASECALLER }   from "${MODULES}/guppy_basecaller.nf"
include { GUPPY_BARCODER }     from "${MODULES}/guppy_barcode.nf"
include { GUPPY_PLEX }         from "${MODULES}/guppy_plex.nf"

include { DORADO_BASECALLER }  from "${MODULES}/dorado_basecaller.nf"
include { DORADO_BARCODER }    from "${MODULES}/dorado_barcoder.nf"

include { PLEX_FQ_FILES }      from "${MODULES}/plex_fq_files.nf"
include { PLEX_DIRS }          from "${MODULES}/plex_dirs.nf"

include { MINIMAP2 }           from "${MODULES}/minimap2.nf"
include { ALIGN_TRIM_1 }       from "${MODULES}/align_trim-1.nf"
include { ALIGN_TRIM_2 }       from "${MODULES}/align_trim-2.nf"
include { MEDAKA_1 }           from "${MODULES}/medaka-1.nf"
include { MEDAKA_2 }           from "${MODULES}/medaka-2.nf"
include { MEDAKA_SNP_1 }       from "${MODULES}/medaka_snp-1.nf"
include { MEDAKA_SNP_2 }       from "${MODULES}/medaka_snp-2.nf"
include { VCF_MERGE }          from "${MODULES}/vcf_merge.nf"
include { LONGSHOT }           from "${MODULES}/longshot.nf"
include { VCF_FILTER }         from "${MODULES}/vcf_filter.nf"
include { MAKE_DEPTH_MASK }    from "${MODULES}/make_depth_mask.nf"
include { MASK }               from "${MODULES}/mask.nf"
include { BCFTOOLS_CONSENSUS } from "${MODULES}/bcftools_consensus.nf"
include { FASTA_HEADER }       from "${MODULES}/fasta_header.nf"
include { CONCAT_FOR_MUSCLE }  from "${MODULES}/concat_for_muscle.nf"
include { MUSCLE }             from "${MODULES}/muscle.nf"
include { CONCAT }             from "${MODULES}/concat.nf"
include { MAFFT }              from "${MODULES}/mafft.nf"
include { SUMMARY_STATS }      from "${MODULES}/summary_stats.nf"
include { REPORT }             from "${MODULES}/report.nf"

// -----------------------------------------------------------------------------
// Param defaults (CLI/GUI can override). No filesystem ops at compile time.
// -----------------------------------------------------------------------------
params.out_dir    = params.output_dir    ?: 'results'
params.fastq_dir     = params.fastq_dir     ?: 'raw_files/fastq'
params.rawfile_dir   = params.rawfile_dir   ?: 'raw_files'          // fast5/pod5 parent dir
params.rawfile_type  = params.rawfile_type  ?: 'fastq'              // 'fastq' | 'fast5_pod5'
params.basecaller    = params.basecaller    ?: 'Dorado'             // 'Dorado' | 'Guppy'
params.fq_extension  = params.fq_extension  ?: '.fastq'
params.threads       = (params.threads ?: 5) as int

// Common model/config params should already be set in nextflow.config (as you have)

// -----------------------------------------------------------------------------
// Sample sheet: require GUI/CLI to provide --sample_sheet (CSV with header)
// Expect columns: sampleId, barcode, schema, version
// -----------------------------------------------------------------------------
if( !params.sample_sheet ) {
  exit 1, "No sample sheet provided. Set --sample_sheet via EPI2ME GUI or CLI."
}
def sampleSheet = file(params.sample_sheet)
if( !sampleSheet.exists() ) {
  exit 1, "Sample sheet not found: ${sampleSheet}"
}

// Build CSV channel (light validation)
Channel
  .fromPath(sampleSheet, checkIfExists: true)
  .splitCsv(header: true, sep: ',')
  .map { row ->
      def sid     = (row.sampleId ?: '').toString().trim()
      def barcode = (row.barcode  ?: '').toString().trim()
      def scheme  = (row.schema   ?: '').toString().trim()
      def version = (row.version  ?: '').toString().trim()
      if( !sid || !barcode || !scheme || !version )
          throw new IllegalArgumentException("Sample sheet row missing fields: ${row}")
      tuple(sid, barcode, scheme, version)
  }
  .set { fq_channel }

// -----------------------------------------------------------------------------
// Pretty logs (no mkdirs/prefetching here; processes handle their own outputs)
// -----------------------------------------------------------------------------
log.info ""
log.info "=== RAGE-toolkit/Artic-nf ==="
log.info "Output dir       : ${params.out_dir}"
log.info "Sample sheet     : ${sampleSheet}"
log.info "Rawfile type     : ${params.rawfile_type}"
log.info "Basecaller       : ${params.basecaller}"
log.info "FASTQ dir        : ${params.fastq_dir}"
log.info "Rawfile dir      : ${params.rawfile_dir}"
log.info "Threads          : ${params.threads}"
log.info "=============================="

def script_ch  = Channel.fromPath("${projectDir}/scripts/directory_plex.py", checkIfExists: true)
def align_trim_script	=	Channel.fromPath("${projectDir}/scripts/align_trim.py")
def vcf_merge_script	=	Channel.fromPath("${projectDir}/scripts/vcf_merge.py")
def vcf_filter_script = Channel.fromPath("${projectDir}/scripts/vcf_filter.py")
def make_depth_mask_script = Channel.fromPath("${projectDir}/scripts/make_depth_mask.py")
def mask_script =  Channel.fromPath("${projectDir}/scripts/mask.py")
def fasta_header_script = Channel.fromPath("${projectDir}/scripts/fasta_header.py")
def summary_stats_script = Channel.fromPath("${projectDir}/scripts/summary_stats.py")
def report_script = Channel.fromPath("${projectDir}/scripts/report.py")

def medaka_dir = Channel.fromPath("${params.out_dir}/medaka")
def summary_stats_dir = Channel.fromPath("${params.out_dir}/summary_stats")

//def reference = Channel.fromPath("/Users/sandeep.kasaragod/epi2melabs/workflows/sandeepkasaragod/test_gui/meta_data/primer-schemes/rabvPeru2/V1/rabvPeru2.reference.fasta")

def ref_ch = fq_channel.map { sid, item, scheme, version ->
	def ref = file("${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta")
	if( !ref.exists() ) throw new IllegalArgumentException("Missing reference for ${scheme}/${version} -> ${ref}")
	ref
}

def bed_ch = fq_channel.map { sid, item, scheme, version ->
	def bed = file("${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed")
	if( !bed.exists() ) throw new IllegalArgumentException("Missing bed file for ${scheme}/${version} -> ${bed}")
	bed
}


// -----------------------------------------------------------------------------
//  - MINIMAP2 and downstream take the prepared inputs plus fq_channel.
// -----------------------------------------------------------------------------
workflow {

  if( params.rawfile_type == 'fastq' ) {
    // FASTQ already available under params.fastq_dir
    PLEX_DIRS(params.rawfile_dir, script_ch, fq_channel)
    MINIMAP2(PLEX_DIRS.out.reads.collect(), ref_ch, fq_channel)
  }
  else {
    // Need to basecall+demux first from FAST5/POD5
    if( params.basecaller == 'Dorado' ) {
      //DORADO_BASECALLER(fast5_or_pod5_dir: params.rawfile_dir)
      //DORADO_BARCODER(fastq_file: DORADO_BASECALLER.out)
      //PLEX_FQ_FILES(DORADO_BARCODER.out, fq_channel)
      //MINIMAP2(input_dir: PLEX_FQ_FILES.out.collect(), fq_channel)
    }
    else {
      // Guppy path
      //GUPPY_BASECALLER(fast5_or_pod5_dir: params.rawfile_dir)
      //GUPPY_BARCODER(fastq_file: GUPPY_BASECALLER.out)
      //PLEX_DIRS(input_dir: GUPPY_BARCODER.out, fq_channel)
      //MINIMAP2(input_dir: PLEX_DIRS.out.collect(), fq_channel)
    }
  }

  // Downstream graph (kept identical to your original)
  ALIGN_TRIM_1(MINIMAP2.out.sorted_bam.collect(), align_trim_script, bed_ch, fq_channel)
  ALIGN_TRIM_2(ALIGN_TRIM_1.out.trimmed_bam.collect(), align_trim_script, bed_ch, fq_channel)
  MEDAKA_1(ALIGN_TRIM_1.out.trimmed_bam.collect(), fq_channel)
  MEDAKA_2(ALIGN_TRIM_2.out.primertrimmed_bam.collect(), MEDAKA_1.out.hdf, fq_channel)
  MEDAKA_SNP_1(MEDAKA_2.out.hdf.collect(), MEDAKA_1.out.hdf, ref_ch, fq_channel)
	MEDAKA_SNP_2(MEDAKA_SNP_1.out.vcf.collect(), MEDAKA_2.out.hdf, ref_ch, fq_channel)
  VCF_MERGE(MEDAKA_SNP_2.out.vcf.collect(), MEDAKA_SNP_1.out.vcf, bed_ch, vcf_merge_script, fq_channel)
  LONGSHOT(VCF_MERGE.out.merged_tbi.collect(), ALIGN_TRIM_2.out.primertrimmed_bam, ref_ch, fq_channel)
  VCF_FILTER(LONGSHOT.out.vcf.collect(), vcf_filter_script, fq_channel)
  MAKE_DEPTH_MASK(VCF_FILTER.out.pass_vcf.collect(), ALIGN_TRIM_2.out.primertrimmed_bam, ref_ch, make_depth_mask_script, fq_channel)
  MASK(MAKE_DEPTH_MASK.out.coverage_mask.collect(), VCF_FILTER.out.fail_vcf, ref_ch, mask_script, fq_channel)
  BCFTOOLS_CONSENSUS(MASK.out.preconsensus.collect(), VCF_FILTER.out.pass_vcf, MAKE_DEPTH_MASK.out.coverage_mask, fq_channel)
  FASTA_HEADER(BCFTOOLS_CONSENSUS.out.consensus_fa.collect(), fasta_header_script, fq_channel)
  CONCAT_FOR_MUSCLE(FASTA_HEADER.out.fasta, ref_ch, fq_channel)
  MUSCLE(CONCAT_FOR_MUSCLE.out.muscle_fa, fq_channel)
  CONCAT(MUSCLE.out.muscle_op_fasta)
  MAFFT(CONCAT.out.genome_fa)
  SUMMARY_STATS(MAFFT.out.mafft_fa, medaka_dir, summary_stats_script)
  REPORT(SUMMARY_STATS.out.summary, medaka_dir, summary_stats_dir, report_script)
}

