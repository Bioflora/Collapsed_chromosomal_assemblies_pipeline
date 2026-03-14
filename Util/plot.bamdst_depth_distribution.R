#! Rscript

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(cowplot))

args <- commandArgs(T)
file = args[1]
x_min = args[2]
x_max = args[3]
print(paste(c(file,x_min,x_max),collapse = "-"))

detect_peak <- function(x,c){
  if(nrow(x) == 1){
    print("no peak detect")
  }else{
    x[,c(ncol(x)+1)] = "normal"
    for(i in 2:c(nrow(x)-1)){
      x1 = (x[i,c] - x[i-1,c])
      x2 = (x[i,c] - x[i+1,c])
      if(x1 * x2 > 0){
        x[i,8] = "peak"
      }
    }
  }
  return(x)
}

zero_one_norm <- function(x){
  max = max(x)
  min = min(x)
  t = (x-min)/(max-min)
  return(t)
}

d <- read.table(file)
d <- d[c(seq(x_min,x_max,1)),]
formula <- y ~ x
t <- loess(V2 ~ V1,d,span = 0.1)
d$V6 <-  predict(t)
d$V7 = d[,6]/1000000
d <- detect_peak(d,7)
d$V9 <- zero_one_norm(d$V2)
d$V10 = 1-d$V5
colnames(d) <- c("depth","fre","rate","count","rev_cum","pre","pre2","class","fre2","cum")

file_o1 = paste(file,".pdf",sep ="")
file_o2 = paste(file,".csv",sep ="")
p = ggplot()+
  geom_point(data=d,aes(x=depth,y=cum),size = 3,shape = 1,color = "firebrick3")+
  geom_smooth(data = d,aes(x = depth,y = fre2),color = "grey70",formula = formula,method = "loess",span = 0.1)+
  geom_point(data=d,aes(x=depth,y=fre2),size = 3,shape = 1,color = "navy")+
  geom_text(data = d[d$class == "peak",],aes(x = depth,y = fre2 + 0.05,label = depth))+
  geom_text(data = d[nrow(d),],aes(x = depth,y = cum+0.05,label = round(cum,4)))+
  theme_cowplot()+
  theme(axis.text.x = element_text(angle = 45,vjust = 0.5))+
  scale_x_continuous(breaks = seq(as.numeric(x_min),as.numeric(x_max),10),limits = c(as.numeric(x_min),as.numeric(x_max,10)))+
  labs(x = "depth",y = "")
  
ggsave(file_o1,p,width = 7, height = 5)
