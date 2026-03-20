## step0: 
#hifiasm -o genome -t60 --primary -u0 -l0 --h1 hic.fix_1.fastq.gz --h2 hic.fix_2.fastq.gz ccs.fastq.gz
#hifiasm -o genome -t60 --primary -u0 --h1 hic.fix_1.fastq.gz --h2 hic.fix_2.fastq.gz ccs.fastq.gz
## step1: first_round hic anchoring, don't need cluster very well, but need to split collapsed region
cphasing pipeline -f genome.hic.p_ctg.fa -hic1 hic.fix_1.fastq.gz -hic2 hic.fix_2.fastq.gz -t 100 -n 0:0 --pattern GATC
cd cphasing_output/4.scaffolding; bash to_hic.cmd.sh
## manually adjust in juice box
cphasing utils assembly2agp groups.review.assembly -o groups.review
cphasing utils agp2fasta groups.review.agp ../genome.hic.p_ctg.fa -o groups.review.fasta
cd ..; mkdir 6.split; cd 6.split; ln -s ../4.scaffolding/groups.review.fasta
## recommend rename seqence based on homolog
minimap2 -t 30 -x asm20 --secondary=no ref_g.fa groups.review.fasta > groups.review.fasta.ref_g.paf
perl Util/paf_stat.alignment_length.pl --paf groups.review.fasta.ref_g.paf --min_length_query 20000 --min_length_match 2000 --pr 0 |sort -k1,1 -k4,4n > groups.review.fasta.ref_g.paf.stat
perl Util/paf_stat.alignment_length.summary_best.pl groups.review.fasta.ref_g.paf.stat|cut -f 1,2|perl -ple 's/h\d//'|perl -anle 'print "$F[0]\t$F[0]-$F[1]"' > z.rename.lst
perl Util/fasta_format.rename.pl z.rename.lst groups.review.fasta > groups.review.rename.fasta

## step2: split 
perl Util/fasta_split.N.pl --ref groups.review.rename.fasta
cat groups.review.rename.Nsplit/* > groups.review.rename.split.fasta
samtools faidx groups.review.rename.fasta
perl -anle 'print if $F[1] > 5000000' groups.review.rename.fasta.fai |cut -f 1 > groups.review.rename.fasta.chr.lst
perl Util/cphasing.creat_cluster_table_from_splited_seq.pl groups.review.rename.split.fasta groups.review.rename.fasta.chr.lst > modified.clusters.txt

## step3: detection of collapsed unitig/contig based on mapping depth
##if you want to recover specific collapsed region, you can just create `z.collapsed.contig.10k.lst` by yourself
minimap2 --secondary=no -x map-hifi -a -t 120 ./groups.review.rename.split.fasta ccs.fastq.gz | samtools sort -O bam -@ 20 -T align.tmp -o align_long.sort.bam
perl Util/fasta_convert.window_bed.pl --file groups.review.rename.split.fasta --mode bamdst > groups.review.rename.splitsta.10k.bed
cd align_long
bamdst -p groups.review.rename.splitsta.10k.bed -o align_long align_long.sort.bam
perl Util/split.col.pl region.tsv.gz
perl Util/stat.depth_region_interval.pl region.tsv.gz.split 30,120 > region.tsv.gz.split.stat
perl -anle 'print $_ if ($F[4] > 0.2 && $F[5] >= 10)' region.tsv.gz.split.stat |cut -f 1 > z.collapsed.contig.10k.lst
cd ..
mv cphasing_output cphasing_output_0
cd ..

## step4: re-hic mapping (avoid potential bug when cphasing generate collapse interaction map with splited sequence)
cphasing pipeline -f groups.review.rename.split.fasta -hic1 hic.fix_1.fastq.gz -hic2 hic.fix_2.fastq.gz -t 100 -n 0:0 --pattern GATC --steps 1,2,3
mkdir cphasing_output/4.scaffold && cd cphasing_output/4.scaffold
## mv modified.clusters.txt to here
cphasing scaffolding modified.clusters.txt ../2.prepare/hic.fix.counts_GATC.txt ../2.prepare/hic.fix.clm.gz -at ../3.hyperpartition/hic.fix.allele.table -sc ../2.prepare/hic.fix.split.contacts -f ../groups.review.rename.split.fasta -t 100 -o groups.agp -m precision;
cphasing-rs pairs2mnd -q 1 ../hic.fix.pairs.pqs -o hic.fix.pqs.mnd.txt
cphasing utils agp2assembly groups.agp -o groups.assembly
bash path/to/3d-dna/visualize/run-assembly-visualizer.sh -p true groups.assembly .pqs.mnd.txt
## manually adjust in juice box. in most of case case, you do not to change anything if you have already adjusted it properly in inital hic anchoring, but i add this step to double check
cphasing utils assembly2agp groups.review.assembly -o groups.review

## step5: recover collapsed region and adjust manually
cd cphasing_output; mkdir 6.collapse; cd 6.collapse
cut -f 1,2 ../groups.review.rename.split.fasta.fai > contig.len.txt
ln -s path/to/z.collapsed.contig.10k.lst ./
perl Util/hic/agp.make_duplication.pl ../4.scaffolding/groups.review.agp z.collapsed.unitig.10k.lst contig.len.txt > groups.review.add.agp
cphasing collapse agp-dup groups.review.add.agp -o groups.review.add.dup.agp
#perl ~/code/hic/agp.re_check_cphasing_collapse_agp-dup.pl groups.review.add.dup.agp z.collapsed.unitig.10k.lst > groups.review.add.dup.agp.fix
#mv groups.review.add.dup.agp.fix groups.review.add.dup.agp
#grep 'd2' groups.review.add.dup.agp |cut -f 6 |perl -nle '$t = $_; $t =~ s/\_d2//;print "$t\t$_"' > duplicated.contigs.txt
grep '_d' groups.review.add.dup.agp |cut -f 6 |perl -nle '$t = $_; $t =~ s/\_d\d+//;print "$t\t$_"' > duplicated.contigs.txt
cphasing collapse pairs-dup ../genome.hic.fix.pairs.pqs duplicated.contigs.txt -o ../genome.hic.fix.pairs.collapse.pqs
cphasing-rs pairs2mnd -q 1 ../genome.hic.fix.pairs.collapse.pqs -o genome.hic.fix.pqs.collapse.mnd.txt
cphasing utils agp2assembly groups.review.add.dup.agp -o groups.review.add.dup.assembly
bash path/to/3d-dna/visualize/run-assembly-visualizer.sh -p true groups.review.add.dup.assembly genome.hic.fix.pqs.collapse.mnd.txt
# manually adjust in juice box #

## step6: get finally genome assembly
cphasing utils assembly2agp groups.review.add.dup.review.assembly -o groups.review.add.dup.review
perl Util/fasta_format.make_dup.pl duplicated.contigs.txt ../groups.review.rename.split.fasta > groups.review.rename.split.dup.fasta
cphasing utils agp2fasta groups.review.add.dup.review.agp groups.review.rename.split.dup.fasta -o groups.review.add.dup.review.fasta

