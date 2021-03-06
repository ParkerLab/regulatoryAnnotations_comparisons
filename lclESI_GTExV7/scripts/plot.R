library(ggplot2)
library(reshape2)
library(scales)
library(ggrepel)
library(dplyr)
library(forcats)
# Name Description tpm esi
args <- commandArgs(TRUE)
d <- read.table(gzfile(args[1]), header=T, sep='\t')

subsetByCellType <- function(d, subsetList){
    return(subset(d, cell %in% subsetList))
}

## Plot scatter for iESI vs TPM
makeScatterPlot <- function(d){
    d <- subsetByCellType(d, c("Cells - EBV-transformed lymphocytes","Adipose - Subcutaneous","Brain - Cortex","Colon - Sigmoid","Heart - Left Ventricle","Liver","Lung","Pancreas","Spleen", "Testis","Whole Blood"))
    d$cell <- factor(d$cell, levels=c("Cells - EBV-transformed lymphocytes","Adipose - Subcutaneous","Brain - Cortex","Colon - Sigmoid","Heart - Left Ventricle","Liver","Lung","Pancreas","Spleen", "Testis","Whole Blood"))

    p <- ggplot(d, aes(y=tpm, x=lclesi)) +
        geom_point(aes(colour=as.factor(lclesi_bin)), shape=16, size=1, alpha=0.3) +
        facet_wrap(~cell) +
        theme(legend.position="bottom", strip.text.x=element_text(size=7), axis.text.x = element_text(vjust=1, hjust=0.5, size=8), axis.text.y=element_text(size=8),legend.text=element_text(size=8), panel.background = element_rect(fill = 'white', colour = 'black')) +
        labs(y="Gene TPM in respective tissue", x="LCL expression specificity index (lclESI)") +
        scale_y_log10() +
        scale_fill_manual(name="Quintile bin", values=c("blue","lightblue","yellow","orange","red")) + scale_color_manual(name="Quintile bin", values=c("blue","lightblue","yellow","orange","red"))
    return(p)
}

## Plot iESI denisity
makeDensityPlot <- function(d){
    dplot <- subsetByCellType(d, "Cells - EBV-transformed lymphocytes")
    dplot <- dplot[complete.cases(dplot[ , c("lclesi","lclesi_bin")]),]
    lmin <- unlist(lapply(sort(unique(dplot$lclesi_bin)), function(i){
        return(min(subset(dplot, lclesi_bin==i)$lclesi))
    }), use.names=FALSE)
    lmax <- unlist(lapply(sort(unique(dplot$lclesi_bin)), function(i){
        return(max(subset(dplot, lclesi_bin==i)$lclesi))
    }), use.names=FALSE)
    lcol <- c("purple","blue","lightblue","orange","red")
    lmat <- cbind(lmin,lmax, lcol)
    dens <- density(dplot$lclesi)
    dd <- with(dens,data.frame(x,y))
    

    p <- qplot(x,y,data=dd,geom="line") + theme(panel.background = element_rect(fill = 'white', colour = 'black')) #+ coord_flip()
    p <- p + unlist(apply(lmat, 1, function(i){
        ## with(dens, polygon(x=c(i[1], i[1]:i[2], i[2]), y=c(0, y[i[1]:i[2]], 0), col=i[3]))
    geom_ribbon(data=subset(dd, x>=i[1] & x<=i[2]), aes(ymax=y, ymin=0) , fill=i[3], colour=NA, alpha=0.5)
    }), use.names=FALSE)
    return(p)
}

makeHeatmap <- function(d){
    dnew <- data.frame(d %>% group_by(cell, lclesi_bin) %>% summarize(med = median(tpm)))
    dnew$cell <- gsub("Cells - EBV-transformed lymphocytes", ".Cells-EBV-transformed lymphocytes", dnew$cell)
    minE <- min(dnew$med)
    maxE <- max(dnew$med)
    color_scale <- c(0, 0.33*maxE, 0.66*maxE, maxE)
    p <- ggplot(dnew, aes(y=fct_rev(as.factor(cell)), x=lclesi_bin)) +
        geom_tile(aes(fill=med), colour="black") +
        scale_fill_gradientn(colours=c("white","pink", "red", "darkred"), values=rescale(color_scale), breaks=color_scale, labels=round(color_scale, 2), name="Median TPM") +
        theme(strip.text.x=element_text(size=7), axis.text.x = element_text(size=10), axis.text.y=element_text(size=9),legend.text=element_text(size=7), panel.background = element_rect(fill = 'white', colour = 'black')) +
        labs(y="Cell/tissue type", x="lclESI bin")
    return(p)
    }

## legend.position="bottom"

## pdf(args[2], height=8, width=8)
## makeScatterPlot(d)
## dev.off()


pdf(args[3], height=3, width=3)
makeDensityPlot(d)
dev.off()
    
## pdf(args[2], height=9, width=6)
## makeHeatmap(d)
## dev.off()
