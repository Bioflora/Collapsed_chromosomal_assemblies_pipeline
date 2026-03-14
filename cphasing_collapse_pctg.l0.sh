## start with ctg (with hifiasm_l0)
## step1: first_round hic, don't need cluster very well, but need to split collapsed region
cphasing pipeline -f genome.hic.p_ctg.fa -hic1 hic.fix_1.fastq.gz -hic2 hic.fix_2.fastq.gz -t 100 -n 0:0 --pattern GATC
cd cphasing_output/4.scaffolding; bash to_hic.cmd.sh
## manually adjust in juice box
cphasing utils assembly2agp groups.review.assembly -o groups.review
cphasing utils agp2fasta groups.review.agp ../genome.hic.p_ctg.fa -o groups.review.fasta
cd ..; mkdir 6.split; cd 6.split; ln -s ../4.scaffolding/groups.review.fasta

## step2: split and re-hic (avoid bug when cphasing generate collapse interaction map with splited sequence)
## recommend rename seqence based on homolog
mga groups.review.fasta ref_g |sh
perl ~/code/paf/paf_stat.alignment_length.pl --paf groups.review.fasta.ref_g.paf --min_length_query 20000 --min_length_match 2000 --pr 0 |sort -k1,1 -k4,4n > groups.review.fasta.ref_g.paf.stat
perl ~/code/paf/paf_stat.alignment_length.summary_best.pl groups.review.fasta.ref_g.paf.stat|cut -f 1,2|perl -ple 's/h\d//'|perl -anle 'print "$F[0]\t$F[0]-$F[1]"' > z.rename.lst
perl ~/code/seq/fasta_format.rename.pl z.rename.lst groups.review.fasta > groups.review.rename.fasta

##split
perl ~/code/seq/fasta_split.N.pl --ref groups.review.rename.fasta
cat groups.review.rename.Nsplit/* > groups.review.rename.split.fasta
samtools faidx groups.review.rename.fasta
perl -anle 'print if $F[1] > 5000000' groups.review.rename.fasta.fai |cut -f 1 > groups.review.rename.fasta.chr.lst
perl ~/code/hic/cphasing.creat_cluster_table_from_splited_seq.pl groups.review.rename.split.fasta groups.review.rename.fasta.chr.lst > modified.clusters.txt

##task1
##if you want to recover specific collapsed region, you can just create `z.collapsed.contig.10k.lst` by yourself
minimap2 --secondary=no -x map-hifi -a -t 120 ./groups.review.rename.split.fasta /home/wenjie/project/Brachypodium_pangenome/z.raw_data/z.hifi_all/Bbois3.ccs.fastq.gz | samtools sort -O bam -@ 20 -T align.tmp -o align_long.sort.bam
perl ~/code/seq/fasta_convert.window_bed.pl --file groups.review.rename.split.fasta --mode bamdst > groups.review.rename.splitsta.10k.bed
command_stat.bamdst.pl ./ groups.review.rename.splitsta.10k.bed |sh;cd align_long
msplitf region.tsv.gz
perl ~/code/bamdst/stat.depth_region_interval.pl region.tsv.gz.split 30,120 > region.tsv.gz.split.stat
perl -anle 'print $_ if ($F[4] > 0.2 && $F[5] >= 10)' region.tsv.gz.split.stat |cut -f 1 > z.collapsed.contig.10k.lst

##task2
cphasing pipeline -f groups.review.rename.split.fasta -hic1 hic.fix_1.fastq.gz -hic2 hic.fix_2.fastq.gz -t 100 -n 0:0 --pattern GATC --steps 1,2,3
#need test step 1,2 and step 1,2,3
#cphasing pipeline -f groups.review.rename.split.fasta -hic1 hic.fix_1.fastq.gz -hic2 hic.fix_2.fastq.gz -t 100 -n 0:0 --pattern GATC --steps 1,2
#mv cphasing_output/4.scaffold cphasing_output/4.scaffold.bak
mkdir cphasing_output/4.scaffold && cd cphasing_output/4.scaffold
cphasing scaffolding modified.clusters.txt ../2.prepare/.counts_GATC.txt ../2.prepare/.clm.gz -at ../.allele.table -sc ../2.prepare/.split.contacts -f ../groups.review.rename.split.fasta -t 100 -o groups.agp -m precision;
cphasing-rs pairs2mnd -q 1 ../.pairs.pqs -o .pqs.mnd.txt
cphasing utils agp2assembly groups.agp -o groups.assembly
bash ~/software/3d-dna/visualize/run-assembly-visualizer.sh -p true groups.assembly .pqs.mnd.txt
## manually adjust in juice box
cphasing utils assembly2agp groups.review.assembly -o groups.review

## step3: recover collapsed region and adjust manually
cd cphasing_output; mkdir 6.collapse; cd 6.collapse
cut -f 1,2 ../groups.review.rename.split.fasta.fai > contig.len.txt
ln -s path/to/z.collapsed.contig.10k.lst ./
perl ~/code/hic/agp.make_duplication.pl ../4.scaffolding/groups.review.agp z.collapsed.unitig.10k.lst contig.len.txt > groups.review.add.agp
cphasing collapse agp-dup groups.review.add.agp -o groups.review.add.dup.agp
#perl ~/code/hic/agp.re_check_cphasing_collapse_agp-dup.pl groups.review.add.dup.agp z.collapsed.unitig.10k.lst > groups.review.add.dup.agp.fix
#mv groups.review.add.dup.agp.fix groups.review.add.dup.agp
#grep 'd2' groups.review.add.dup.agp |cut -f 6 |perl -nle '$t = $_; $t =~ s/\_d2//;print "$t\t$_"' > duplicated.contigs.txt
grep '_d' groups.review.add.dup.agp |cut -f 6 |perl -nle '$t = $_; $t =~ s/\_d\d+//;print "$t\t$_"' > duplicated.contigs.txt
cphasing collapse pairs-dup ../genome.hic.fix.pairs.pqs duplicated.contigs.txt -o ../genome.hic.fix.pairs.collapse.pqs
cphasing-rs pairs2mnd -q 1 ../genome.hic.fix.pairs.collapse.pqs -o genome.hic.fix.pqs.collapse.mnd.txt
cphasing utils agp2assembly groups.review.add.dup.agp -o groups.review.add.dup.assembly
bash ~/software/3d-dna/visualize/run-assembly-visualizer.sh -p true groups.review.add.dup.assembly genome.hic.fix.pqs.collapse.mnd.txt
# manually adjust in juice box #

## step4: get finally genome assembly
cphasing utils assembly2agp groups.review.add.dup.review.assembly -o groups.review.add.dup.review
perl /home/wenjie/code/seq/fasta_format.make_dup.pl duplicated.contigs.txt ../groups.review.rename.split.fasta > groups.review.rename.split.dup.fasta
cphasing utils agp2fasta groups.review.add.dup.review.agp groups.review.rename.split.dup.fasta -o groups.review.add.dup.review.fasta
perl ~/code/seq/fasta_format.rename.pl z.rename.lst groups.review.add.dup.review.fasta > groups.review.add.dup.review.rename.fasta
samtools faidx groups.review.add.dup.review.rename.fasta
