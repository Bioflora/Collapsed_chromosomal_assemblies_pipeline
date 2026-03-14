#0-1
cphasing collapse from-gfa ../../../../genome.hic.p_utg.noseq.gfa
cut -f 1,2 ../genome.hic.p_utg.fa.fai > contig.len.txt
csvtk merge -T -t -f "1;1" -H contigs.collapsed.contig.list contig.len.txt |perl -anle 'print $_ if ($F[3] > 100000)' | cut -f 1 > z.collapsed.unitig.100k.lst

#0-2
minimap2 --secondary=no -x map-hifi -a -t 60 genome.hic.p_utg.fa ccs.fastq.gz | samtools sort -O bam -@ 10 -T align.tmp -o align_long.sort.bam
perl ~/code/seq/fasta_convert.window_bed.pl --file genome.hic.p_utg.fa --mode bamdst > genome.hic.p_utg.10k.bed
command_stat.bamdst.pl ./ genome.hic.p_utg.10k.bed |sh; cd align_long
Rscript ~/code/bamdst/plot.bamdst_depth_distribution.R depth_distribution.plot 0 100
perl ~/code/bamdst/filter.chromosomes_report.coverage.pl chromosomes.report 0 low 0 |cut -f 1 > z.unmapped.unitig.lst
perl /home/wenjie/code/seq/fasta_grep.ref.pl -v --ref z.unmapped.unitig.lst ../genome.hic.p_utg.fa > ../genome.hic.p_utg.filter_unmap.fa

perl /home/wenjie/code/file/split_file_by_col.pl region.tsv.gz
perl ~/code/bamdst/stat.depth_region_interval.pl region.tsv.gz.split 15,75 |perl -anle 'print $_ if ($F[4] > 0.3 && $F[5] >= 10)' |cut -f 1 > z.collapsed.unitig.100k.lst
cd ..

#1
mkdir z.cphasing
cd z.cphasing; ln -s ../genome.hic.p_utg.filter_unmap.fa genome.hic.p_utg.fa
cphasing pipeline -f genome.hic.p_utg.fa -hic1 ~/project/Brachypodium_pangenome/z.raw_data/Bpho6/Bpho6.hic_1.fix.fq.gz -hic2 ~/project/Brachypodium_pangenome/z.raw_data/Bpho6/Bpho6.hic_2.fix.fq.gz -t 100 -n 5:0 -hcr --pattern GATC
## 5 is the number of homology chromosome group
cd cphasing_output/4.scaffolding
bash to_hic.cmd.sh

#2
#use juicer curate assembly manually
cphasing utils assembly2agp groups.review.assembly -o groups.review
cphasing utils agp2fasta groups.review.agp ../genome.hic.p_utg.fa -o groups.review.fasta
#use `mga groups.review.fasta ref` to check

#3
perl ~/code/hic/agp.make_duplication.pl ../4.scaffolding/groups.review.agp z.collapsed.unitig.100k.lst contig.len.txt > groups.review.add.agp
cphasing collapse agp-dup groups.review.add.agp -o groups.review.add.dup.agp
#perl ~/code/hic/agp.re_check_cphasing_collapse_agp-dup.pl groups.review.add.dup.agp z.collapsed.unitig.10k.lst > groups.review.add.dup.agp.fix
#mv groups.review.add.dup.agp.fix groups.review.add.dup.agp
grep 'd2' groups.review.add.dup.agp |cut -f 6 |perl -nle '$t = $_; $t =~ s/\_d2//;print "$t\t$_"' > duplicated.contigs.txt
cphasing collapse pairs-dup ../Bpho6.hic.fix.pairs.pqs duplicated.contigs.txt -o ../Bpho6.hic.fix.pairs.collapse.pqs
cphasing-rs pairs2mnd -q 1 ../Bpho6.hic.fix.pairs.collapse.pqs -o Bpho6.hic.fix.pqs.collapse.mnd.txt
cphasing utils agp2assembly groups.review.add.dup.agp -o groups.review.add.dup.assembly
bash ~/software/3d-dna/visualize/run-assembly-visualizer.sh -p true groups.review.add.dup.assembly Bpho6.hic.fix.pqs.collapse.mnd.txt

#4
#use juicer curate assembly manually
cphasing utils assembly2agp groups.review.add.dup.review.final.assembly -o groups.review.add.dup.review.final
ln -s ../6.collapse/duplicated.contigs.txt ./
perl /home/wenjie/code/seq/fasta_format.make_dup.pl duplicated.contigs.txt ../genome.hic.p_utg.fa > genome.hic.p_utg.dup.fa
cphasing utils agp2fasta groups.review.add.dup.review.final.agp genome.hic.p_utg.dup.fa -o groups.review.final.fasta
#use `mga xxxx.fa ref` to check

