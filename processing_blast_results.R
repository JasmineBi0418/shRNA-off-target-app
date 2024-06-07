suppressPackageStartupMessages({
  library(readr,quietly = TRUE)
  library(dplyr,quietly = TRUE)
  library(tidyverse,quietly = TRUE)
  library(openxlsx,quietly = TRUE)
  library(org.Mm.eg.db,quietly = TRUE)
  })
options(warn = -1)
suppressMessages({
  results<-read.delim('output/Blast_results.txt',sep="\t",header = FALSE)
  colnames(results)<-c("qseqid", "sseqid", "length", "mismatch", "gapopen", "qstart", "qend", "sstart", "send", "evalue", "bitscore", "sstrand")
  results<-separate(results,sseqid,into='REFSEQ',sep = "[.]")
  cols <- c("SYMBOL", "GENENAME")
  results$REFSEQ<-gsub("[ref|]","",results$REFSEQ)
  anno_results<-select(org.Mm.eg.db, keys=unique(results$REFSEQ), columns=cols, keytype="REFSEQ")
  results_full<-left_join(results,anno_results,by="REFSEQ")%>%unique()
  #write.csv(results_full,"output/results_full.csv",row.names = FALSE)
  results_full2<-results_full%>%dplyr::select(!REFSEQ)%>%dplyr::select(qseqid,length,qstart,qend,SYMBOL,GENENAME)%>%filter(!is.na(SYMBOL))%>%unique()
  results_full3 <- results_full2 %>%
    group_by(qseqid,SYMBOL) %>%
    slice_max(order_by = length, n = 1) %>%
    ungroup()
  
  colnames(results_full3)<-c("shRNA","Match Length","shRNA Start","shRNA End","Target Gene Symbol","Target Gene Name")
  #write.csv(results_full3,"output/results_deduped.csv",row.names = FALSE)
  #results_full_solidated<-results_full2%>%group_by(qseqid,SYMBOL,GENENAME,qstart,qend,)%>%filter(!is.na(SYMBOL))%>%count()
  #colnames(results_full_solidated)<-c("shRNA","Target Gene Symbol","Target Gene Name","Mapped Count")
  wb <- createWorkbook()
  for (sh in unique(results$qseqid)){
    addWorksheet(wb, sh)
    data<-results_full3%>%filter(shRNA==sh)%>%arrange(desc(`Match Length`))
    filename<-paste("output/",sh,".csv",sep="")
    write.csv(data,filename,row.names = FALSE)
    writeData(wb, sheet = sh, data)
  }
  addWorksheet(wb, "Full Data")
  writeData(wb, sheet = "Full Data", results_full)
  saveWorkbook(wb, "output/Final Report.xlsx", overwrite = TRUE)
})
