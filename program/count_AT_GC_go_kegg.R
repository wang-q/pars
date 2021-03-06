#!/usr/bin/env Rscript

library(getopt)
library(ape)
library(ggplot2)
library(scales)
library(reshape)
library(pander)
library(gridExtra)
library(plyr)
library(dplyr)
library(proto)
library(gsubfn)
library(RSQLite)
library(sqldf)

spec = matrix(
    c(
        "help",
        "h",
        0,
        "logical",
        "brief help message",

        "name",
        "n",
        1,
        "character",
        "input name",
        
        "outfile",
        "o",
        1,
        "character",
        "output filename"
    ),
    byrow = TRUE,
    ncol = 5
)
opt = getopt(spec)
#name <- "Scer_n128_Spar.update"
name <- opt$name
path <- paste0("~/data/mrna-structure/result/", name, collapse = NULL)
setwd(path)

#输入csv
file_SNPs_PARS_mRNA <- paste0(path,'/data_SNPs_PARS_mRNA.tsv',collapse = NULL)
data_SNPs_PARS_mRNA <- read.csv(file_SNPs_PARS_mRNA,header = TRUE,sep = "\t")
dd_SNP <- data.frame(name = "mRNA",SNP = c(nrow(data_SNPs_PARS_mRNA)))
data_gene_process <- data_SNPs_PARS_mRNA["gene"]
dd_gene<- data.frame(name = "mRNA", gene = c(nrow(data_gene_process)))

data_SNPs_PARS_cds <- sqldf('SELECT * FROM [data_SNPs_PARS_mRNA] where CDS_position != "-"')
dd_SNP <- rbind(dd_SNP, data.frame(name="cds", SNP=nrow(data_SNPs_PARS_cds)))
dd_gene <- rbind(dd_gene, data.frame(name="cds", gene=nrow(unique(data_SNPs_PARS_cds["gene"],fromLast=TRUE))))

#CC
file_gene_CC <- "Scer_n128_Spar_GO.CC.csv" 
data_gene_CC <- read.csv(file_gene_CC,header = FALSE ,sep = ",")
colnames(data_gene_CC) <- c(1:72)
for (cc in 1:72){
  gene <- data.frame(data_gene_CC[3:nrow(data_gene_CC),cc],row.names = NULL)
  colnames(gene) <- "gene"
  snp <- assign(paste0("data_SNPs_PARS_cds_CC_",cc),merge(data_SNPs_PARS_cds,gene,by="gene"))
  dd_SNP <- rbind(dd_SNP,data.frame(name=paste0("CC_",cc,"_",data_gene_CC[2,cc]),SNP = c(nrow(snp))))
  data_gene_process <- snp["gene"]
  data_gene_process <- unique(data_gene_process,fromLast=TRUE)
  dd_gene <- rbind(dd_gene, data.frame(name = data_gene_CC[2,cc], gene = c(nrow(data_gene_process))))
  write.csv(data_gene_process , file=paste0(path,'/freq_10/GO/CC_gene_',cc,"_",data_gene_CC[2,cc],".csv"), row.names = FALSE)
  write.csv(snp , file=paste0(path,'/freq_10/GO/CC_SNP_',cc,"_",data_gene_CC[2,cc],".csv"), row.names = FALSE)
  
    if(max(snp$freq)>=10){
      for(i in 1:10){
        # 统计每个freq的总SNPs和总gene的情况
        n <- assign(paste0('snp_',i,collapse = NULL),subset(snp,freq <= max(freq)*(i/10) & freq > max(freq)*((i-1)/10)))
        if(i==1){
          dd_SNPs_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(n)))
        }else{
          dd_SNPs_freq <- rbind(dd_SNPs_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(n)))
        }
        data_gene_process <- n["gene"]
        data_gene_process <- unique(data_gene_process,fromLast=TRUE)
        if(i==1){
          dd_gene_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), gene = c(nrow(data_gene_process)))
        }else{
          dd_gene_freq <- rbind(dd_gene_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), gene = nrow(data_gene_process) ))
        }  
        # 统计每个freq的stem-loop的SNPs和gene的情况 
        'stem'
        
        data_stem <- subset(n,(structure == "stem"))
        if(i==1){
          dd_SNPs_freq_stem <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem)))
        }else{
          dd_SNPs_freq_stem <- rbind(dd_SNPs_freq_stem, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem)))
        }
        
        data_stem_AT_GC <- sqldf('SELECT * FROM [data_stem] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
        if(i==1){
          dd_SNPs_freq_stem_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_AT_GC)))
        }else{
          dd_SNPs_freq_stem_AT_GC <- rbind(dd_SNPs_freq_stem_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_AT_GC)))
        }
        
        data_stem_GC_AT <- sqldf('SELECT * FROM [data_stem] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
        if(i==1){
          dd_SNPs_freq_stem_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_GC_AT)))
        }else{
          dd_SNPs_freq_stem_GC_AT <- rbind(dd_SNPs_freq_stem_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_GC_AT)))
        }
        
        'loop'
        
        data_loop <- subset(n,(structure == "loop"))
        if(i==1){
          dd_SNPs_freq_loop <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop)))
        }else{
          dd_SNPs_freq_loop <- rbind(dd_SNPs_freq_loop, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop)))
        }
        
        data_loop_AT_GC <- sqldf('SELECT * FROM [data_loop] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
        if(i==1){
          dd_SNPs_freq_loop_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_AT_GC)))
        }else{
          dd_SNPs_freq_loop_AT_GC <- rbind(dd_SNPs_freq_loop_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_AT_GC)))
        }
        
        data_loop_GC_AT <- sqldf('SELECT * FROM [data_loop] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
        if(i==1){
          dd_SNPs_freq_loop_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_GC_AT)))
        }else{
          dd_SNPs_freq_loop_GC_AT <- rbind(dd_SNPs_freq_loop_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_GC_AT)))
        }
        
        assign(paste0('data_stat_',i),data.frame(structure=c("stem","loop"),AT_GC=c(nrow(data_stem_AT_GC),nrow(data_loop_AT_GC)),GC_AT=c(nrow(data_stem_GC_AT),nrow(data_loop_GC_AT))))
        
      }
      # 合并多个数据框
      data <- lapply(paste0('data_stat_',1:10), function(data_stat_) eval(as.name(data_stat_)))
      data_stat <- do.call("rbind", data)
      
      write.csv(data_stat, file=paste0(path,'/freq_10/GO/CC_stat_',cc,"_",data_gene_CC[2,cc],'_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_SNPs_freq_10.csv'), row.names = FALSE)
      write.csv(dd_gene_freq, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_gene_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_stem, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_stem_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_loop, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_loop_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_stem_AT_GC, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_stem_AT_GC_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_loop_AT_GC, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_loop_AT_GC_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_stem_GC_AT, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_stem_GC_AT_freq_10.csv'), row.names = FALSE)
      write.csv(dd_SNPs_freq_loop_GC_AT, file=paste0(path,'/freq_10/GO/CC_',cc,'_stat_loop_GC_AT_freq_10.csv'), row.names = FALSE)
    }
    
}
  
#BP
file_gene_BP <- "Scer_n128_Spar_GO.BP.csv" 
data_gene_BP <- read.csv(file_gene_BP,header = FALSE ,sep = ",")
colnames(data_gene_BP) <- c(1:123)
for (bp in 1:123){
  gene <- data.frame(data_gene_BP[3:nrow(data_gene_BP),bp],row.names = NULL)
  colnames(gene) <- "gene"
  snp <- assign(paste0("data_SNPs_PARS_cds_BP_",bp),merge(data_SNPs_PARS_cds,gene,by="gene"))
  dd_SNP <- rbind(dd_SNP,data.frame(name=paste0("BP_",bp,"_",data_gene_BP[2,bp]),SNP = c(nrow(snp))))
  data_gene_process <- snp["gene"]
  data_gene_process <- unique(data_gene_process,fromLast=TRUE)
  dd_gene <- rbind(dd_gene, data.frame(name = data_gene_BP[2,bp], gene = c(nrow(data_gene_process))))
  write.csv(data_gene_process , file=paste0(path,'/freq_10/GO/BP_gene_',bp,"_",data_gene_BP[2,bp],".csv"), row.names = FALSE)
  write.csv(snp , file=paste0(path,'/freq_10/GO/BP_SNP_',bp,"_",data_gene_BP[2,bp],".csv"), row.names = FALSE)
  
  if(max(snp$freq)>=10){
    for(i in 1:10){
      # 统计每个freq的总SNPs和总gene的情况
      n <- assign(paste0('snp_',i,collapse = NULL),subset(snp,freq <= max(freq)*(i/10) & freq > max(freq)*((i-1)/10)))
      if(i==1){
        dd_SNPs_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(n)))
      }else{
        dd_SNPs_freq <- rbind(dd_SNPs_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(n)))
      }
      data_gene_process <- n["gene"]
      data_gene_process <- unique(data_gene_process,fromLast=TRUE)
      if(i==1){
        dd_gene_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), gene = c(nrow(data_gene_process)))
      }else{
        dd_gene_freq <- rbind(dd_gene_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), gene = nrow(data_gene_process) ))
      }  
      # 统计每个freq的stem-loop的SNPs和gene的情况 
      'stem'
      
      data_stem <- subset(n,(structure == "stem"))
      if(i==1){
        dd_SNPs_freq_stem <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem)))
      }else{
        dd_SNPs_freq_stem <- rbind(dd_SNPs_freq_stem, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem)))
      }
      
      data_stem_AT_GC <- sqldf('SELECT * FROM [data_stem] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_stem_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_AT_GC)))
      }else{
        dd_SNPs_freq_stem_AT_GC <- rbind(dd_SNPs_freq_stem_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_AT_GC)))
      }
      
      data_stem_GC_AT <- sqldf('SELECT * FROM [data_stem] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_stem_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_GC_AT)))
      }else{
        dd_SNPs_freq_stem_GC_AT <- rbind(dd_SNPs_freq_stem_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_GC_AT)))
      }
      
      'loop'
      
      data_loop <- subset(n,(structure == "loop"))
      if(i==1){
        dd_SNPs_freq_loop <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop)))
      }else{
        dd_SNPs_freq_loop <- rbind(dd_SNPs_freq_loop, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop)))
      }
      
      data_loop_AT_GC <- sqldf('SELECT * FROM [data_loop] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_loop_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_AT_GC)))
      }else{
        dd_SNPs_freq_loop_AT_GC <- rbind(dd_SNPs_freq_loop_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_AT_GC)))
      }
      
      data_loop_GC_AT <- sqldf('SELECT * FROM [data_loop] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_loop_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_GC_AT)))
      }else{
        dd_SNPs_freq_loop_GC_AT <- rbind(dd_SNPs_freq_loop_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_GC_AT)))
      }
      
      assign(paste0('data_stat_',i),data.frame(structure=c("stem","loop"),AT_GC=c(nrow(data_stem_AT_GC),nrow(data_loop_AT_GC)),GC_AT=c(nrow(data_stem_GC_AT),nrow(data_loop_GC_AT))))
      
    }
    # 合并多个数据框
    data <- lapply(paste0('data_stat_',1:10), function(data_stat_) eval(as.name(data_stat_)))
    data_stat <- do.call("rbind", data)
    
    write.csv(data_stat, file=paste0(path,'/freq_10/GO/BP_stat_',bp,"_",data_gene_BP[2,bp],'_freq_10.csv'), row.names = FALSE)
    paste0(path,'/freq_10/GO/BP_stat_',bp,"_",data_gene_BP[2,bp],'_freq_10.csv')
    write.csv(dd_SNPs_freq, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_SNPs_freq_10.csv'), row.names = FALSE)
    write.csv(dd_gene_freq, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_gene_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_stem_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_loop_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_AT_GC, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_stem_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_AT_GC, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_loop_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_GC_AT, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_stem_GC_AT_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_GC_AT, file=paste0(path,'/freq_10/GO/BP_',bp,'_stat_loop_GC_AT_freq_10.csv'), row.names = FALSE)
  }
  
}

#MF
file_gene_MF <- "Scer_n128_Spar_GO.MF.csv" 
data_gene_MF <- read.csv(file_gene_MF,header = FALSE ,sep = ",")
colnames(data_gene_MF) <- c(1:52)
for (mf in 1:52){
  gene <- data.frame(data_gene_MF[3:nrow(data_gene_MF),mf],row.names = NULL)
  colnames(gene) <- "gene"
  snp <- assign(paste0("data_SNPs_PARS_cds_MF_",mf),merge(data_SNPs_PARS_cds,gene,by="gene"))
  dd_SNP <- rbind(dd_SNP,data.frame(name=paste0("MF_",mf,"_",data_gene_MF[2,mf]),SNP = c(nrow(snp))))
  data_gene_process <- snp["gene"]
  data_gene_process <- unique(data_gene_process,fromLast=TRUE)
  dd_gene <- rbind(dd_gene, data.frame(name = data_gene_MF[2,mf], gene = c(nrow(data_gene_process))))
  write.csv(data_gene_process , file=paste0(path,'/freq_10/GO/MF_gene_',mf,"_",data_gene_MF[2,mf],".csv"), row.names = FALSE)
  write.csv(snp , file=paste0(path,'/freq_10/GO/MF_SNP_',mf,"_",data_gene_MF[2,mf],".csv"), row.names = FALSE)
  
  if(max(snp$freq)>=10){
    for(i in 1:10){
      # 统计每个freq的总SNPs和总gene的情况
      n <- assign(paste0('snp_',i,collapse = NULL),subset(snp,freq <= max(freq)*(i/10) & freq > max(freq)*((i-1)/10)))
      if(i==1){
        dd_SNPs_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(n)))
      }else{
        dd_SNPs_freq <- rbind(dd_SNPs_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(n)))
      }
      data_gene_process <- n["gene"]
      data_gene_process <- unique(data_gene_process,fromLast=TRUE)
      if(i==1){
        dd_gene_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), gene = c(nrow(data_gene_process)))
      }else{
        dd_gene_freq <- rbind(dd_gene_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), gene = nrow(data_gene_process) ))
      }  
      # 统计每个freq的stem-loop的SNPs和gene的情况 
      'stem'
      
      data_stem <- subset(n,(structure == "stem"))
      if(i==1){
        dd_SNPs_freq_stem <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem)))
      }else{
        dd_SNPs_freq_stem <- rbind(dd_SNPs_freq_stem, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem)))
      }
      
      data_stem_AT_GC <- sqldf('SELECT * FROM [data_stem] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_stem_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_AT_GC)))
      }else{
        dd_SNPs_freq_stem_AT_GC <- rbind(dd_SNPs_freq_stem_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_AT_GC)))
      }
      
      data_stem_GC_AT <- sqldf('SELECT * FROM [data_stem] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_stem_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_GC_AT)))
      }else{
        dd_SNPs_freq_stem_GC_AT <- rbind(dd_SNPs_freq_stem_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_GC_AT)))
      }
      
      'loop'
      
      data_loop <- subset(n,(structure == "loop"))
      if(i==1){
        dd_SNPs_freq_loop <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop)))
      }else{
        dd_SNPs_freq_loop <- rbind(dd_SNPs_freq_loop, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop)))
      }
      
      data_loop_AT_GC <- sqldf('SELECT * FROM [data_loop] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_loop_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_AT_GC)))
      }else{
        dd_SNPs_freq_loop_AT_GC <- rbind(dd_SNPs_freq_loop_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_AT_GC)))
      }
      
      data_loop_GC_AT <- sqldf('SELECT * FROM [data_loop] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_loop_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_GC_AT)))
      }else{
        dd_SNPs_freq_loop_GC_AT <- rbind(dd_SNPs_freq_loop_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_GC_AT)))
      }
      
      assign(paste0('data_stat_',i),data.frame(structure=c("stem","loop"),AT_GC=c(nrow(data_stem_AT_GC),nrow(data_loop_AT_GC)),GC_AT=c(nrow(data_stem_GC_AT),nrow(data_loop_GC_AT))))
      
    }
    # 合并多个数据框
    data <- lapply(paste0('data_stat_',1:10), function(data_stat_) eval(as.name(data_stat_)))
    data_stat <- do.call("rbind", data)
    
    write.csv(data_stat, file=paste0(path,'/freq_10/GO/MF_stat_',mf,"_",data_gene_MF[2,mf],'_freq_10.csv'), row.names = FALSE)
    paste0(path,'/freq_10/GO/MF_stat_',mf,"_",data_gene_MF[2,mf],'_freq_10.csv')
    write.csv(dd_SNPs_freq, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_SNPs_freq_10.csv'), row.names = FALSE)
    write.csv(dd_gene_freq, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_gene_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_stem_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_loop_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_AT_GC, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_stem_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_AT_GC, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_loop_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_GC_AT, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_stem_GC_AT_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_GC_AT, file=paste0(path,'/freq_10/GO/MF_',mf,'_stat_loop_GC_AT_freq_10.csv'), row.names = FALSE)
  }
  
}

write.csv(dd_gene, file=paste0(path,'/freq_10/GO/dd_gene.csv'), row.names = FALSE)
write.csv(dd_SNP, file=paste0(path,'/freq_10/GO/dd_SNP.csv'), row.names = FALSE)

rm(dd_SNP,dd_gene)

#输入csv
file_SNPs_PARS_mRNA <- paste0(path,'/data_SNPs_PARS_mRNA.tsv',collapse = NULL)
data_SNPs_PARS_mRNA <- read.csv(file_SNPs_PARS_mRNA,header = TRUE,sep = "\t")
dd_SNP <- data.frame(name = "mRNA",SNP = c(nrow(data_SNPs_PARS_mRNA)))
data_gene_process <- data_SNPs_PARS_mRNA["gene"]
dd_gene<- data.frame(name = "mRNA", gene = c(nrow(data_gene_process)))

data_SNPs_PARS_cds <- sqldf('SELECT * FROM [data_SNPs_PARS_mRNA] where CDS_position != "-"')
dd_SNP <- rbind(dd_SNP, data.frame(name="cds", SNP=nrow(data_SNPs_PARS_cds)))
dd_gene <- rbind(dd_gene, data.frame(name="cds", gene=nrow(unique(data_SNPs_PARS_cds["gene"],fromLast=TRUE))))

#KEGG
file_gene_KEGG <- "Scer_n128_Spar_KEGG.csv" 
data_gene_KEGG <- read.csv(file_gene_KEGG,header = FALSE ,sep = ",")
colnames(data_gene_KEGG) <- c(1:30)
for (kegg in 1:30){
  gene <- data.frame(data_gene_KEGG[3:nrow(data_gene_KEGG),kegg],row.names = NULL)
  colnames(gene) <- "gene"
  snp <- assign(paste0("data_SNPs_PARS_cds_KEGG_",kegg),merge(data_SNPs_PARS_cds,gene,by="gene"))
  dd_SNP <- rbind(dd_SNP,data.frame(name=paste0("KEGG_",kegg,"_",data_gene_KEGG[2,kegg]),SNP = c(nrow(snp))))
  data_gene_process <- snp["gene"]
  data_gene_process <- unique(data_gene_process,fromLast=TRUE)
  dd_gene <- rbind(dd_gene, data.frame(name = data_gene_KEGG[2,kegg], gene = c(nrow(data_gene_process))))
  write.csv(data_gene_process , file=paste0(path,'/freq_10/KEGG/KEGG_gene_',kegg,"_",data_gene_KEGG[2,kegg],".csv"), row.names = FALSE)
  write.csv(snp , file=paste0(path,'/freq_10/KEGG/KEGG_SNP_',kegg,"_",data_gene_KEGG[2,kegg],".csv"), row.names = FALSE)
  
  if(max(snp$freq)>=10){
    for(i in 1:10){
      # 统计每个freq的总SNPs和总gene的情况
      n <- assign(paste0('snp_',i,collapse = NULL),subset(snp,freq <= max(freq)*(i/10) & freq > max(freq)*((i-1)/10)))
      if(i==1){
        dd_SNPs_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(n)))
      }else{
        dd_SNPs_freq <- rbind(dd_SNPs_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(n)))
      }
      data_gene_process <- n["gene"]
      data_gene_process <- unique(data_gene_process,fromLast=TRUE)
      if(i==1){
        dd_gene_freq <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), gene = c(nrow(data_gene_process)))
      }else{
        dd_gene_freq <- rbind(dd_gene_freq, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), gene = nrow(data_gene_process) ))
      }  
      # 统计每个freq的stem-loop的SNPs和gene的情况 
      'stem'
      
      data_stem <- subset(n,(structure == "stem"))
      if(i==1){
        dd_SNPs_freq_stem <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem)))
      }else{
        dd_SNPs_freq_stem <- rbind(dd_SNPs_freq_stem, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem)))
      }
      
      data_stem_AT_GC <- sqldf('SELECT * FROM [data_stem] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_stem_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_AT_GC)))
      }else{
        dd_SNPs_freq_stem_AT_GC <- rbind(dd_SNPs_freq_stem_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_AT_GC)))
      }
      
      data_stem_GC_AT <- sqldf('SELECT * FROM [data_stem] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_stem_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_stem_GC_AT)))
      }else{
        dd_SNPs_freq_stem_GC_AT <- rbind(dd_SNPs_freq_stem_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_stem_GC_AT)))
      }
      
      'loop'
      
      data_loop <- subset(n,(structure == "loop"))
      if(i==1){
        dd_SNPs_freq_loop <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop)))
      }else{
        dd_SNPs_freq_loop <- rbind(dd_SNPs_freq_loop, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop)))
      }
      
      data_loop_AT_GC <- sqldf('SELECT * FROM [data_loop] where mutant_to == "A->G" OR mutant_to == "A->C" OR mutant_to == "T->G" OR mutant_to == "T->C"' )
      if(i==1){
        dd_SNPs_freq_loop_AT_GC <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_AT_GC)))
      }else{
        dd_SNPs_freq_loop_AT_GC <- rbind(dd_SNPs_freq_loop_AT_GC, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_AT_GC)))
      }
      
      data_loop_GC_AT <- sqldf('SELECT * FROM [data_loop] where mutant_to == "G->A" OR mutant_to == "C->A" OR mutant_to == "G->T" OR mutant_to == "C->T"')  
      if(i==1){
        dd_SNPs_freq_loop_GC_AT <- data.frame(name = paste0("0-",i,"0%",collapse = NULL), SNPs = c(nrow(data_loop_GC_AT)))
      }else{
        dd_SNPs_freq_loop_GC_AT <- rbind(dd_SNPs_freq_loop_GC_AT, data.frame(name = paste0(i-1,"0","-",i,"0%",collapse = NULL), SNPs = nrow(data_loop_GC_AT)))
      }
      
      assign(paste0('data_stat_',i),data.frame(structure=c("stem","loop"),AT_GC=c(nrow(data_stem_AT_GC),nrow(data_loop_AT_GC)),GC_AT=c(nrow(data_stem_GC_AT),nrow(data_loop_GC_AT))))
      
    }
    # 合并多个数据框
    data <- lapply(paste0('data_stat_',1:10), function(data_stat_) eval(as.name(data_stat_)))
    data_stat <- do.call("rbind", data)
    
    write.csv(data_stat, file=paste0(path,'/freq_10/KEGG/KEGG_stat_',kegg,"_",data_gene_KEGG[2,kegg],'_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_SNPs_freq_10.csv'), row.names = FALSE)
    write.csv(dd_gene_freq, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_gene_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_stem_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_loop_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_AT_GC, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_stem_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_AT_GC, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_loop_AT_GC_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_stem_GC_AT, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_stem_GC_AT_freq_10.csv'), row.names = FALSE)
    write.csv(dd_SNPs_freq_loop_GC_AT, file=paste0(path,'/freq_10/KEGG/KEGG_',kegg,'_stat_loop_GC_AT_freq_10.csv'), row.names = FALSE)
  }
  
}

write.csv(dd_gene, file=paste0(path,'/freq_10/KEGG/dd_gene.csv'), row.names = FALSE)
write.csv(dd_SNP, file=paste0(path,'/freq_10/KEGG/dd_SNP.csv'), row.names = FALSE)
