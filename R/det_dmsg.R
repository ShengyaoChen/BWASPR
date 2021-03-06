#' det_dmsg()
#'   This function generates list of differentially methylated CpG sites and the
#'   corresponding genes, as determined by application of methylKit functions.
#'
#' @param mrobj A methylRaw object or a methylRawList object.
#' @param genome_ann Genome annotation returned by get_genome_annotation()
#' @param threshold Cutoff for percent methylation difference, default threshold = 25.0
#' @param qvalue Cutoff for q-value, defualt q-value = 0.01
#' @param mc.cores Integer denoting how many cores should be used for parallel
#'   diffential methylation calculations
#' @param destrand methylKit::unite() parameter; default: FALSE.
#'   destrand=TRUE combines CpG methylation calls from both strands.
#' @param outfile1 File name to which diff sites are written
#' @param outfile2 File name to which diff genes are written
#'
#' @return A Granges object that contains a list of genes that have diff methylated C sites
#'
#' @import methylKit
#' @importFrom GenomicRanges GRangesList
#' @importFrom IRanges subsetByOverlaps
#' @import BiocGenerics
#' @importFrom S4Vectors mcols
#'
#' @examples
#'   mydatf <- system.file("extdata","Am.dat",package="BWASPR")
#'   myparf <- system.file("extdata","Am.par",package="BWASPR")
#'   myfiles <- setup_BWASPR(datafile=mydatf,parfile=myparf)
#'   AmHE <- mcalls2mkobj(myfiles$datafiles,species="Am",study="HE",type="CpGhsm",
#'                        mincov=1,assembly="Amel-4.5")
#'   genome_ann <- get_genome_annotation(myfiles$parameters)
#'   meth_diff <- det_dmsg(AmHE,genome_ann,threshold=25.0,qvalue=0.01,mc.cores=4,
#'                         outfile1="AmHE-dmsites.txt", 
#'                         outfile2="AmHE-dmgenes.txt") 
#'
#' @export

det_dmsg <- function(mrobj,genome_ann,threshold=25.0,qvalue=0.01,mc.cores=1,
                     destrand=FALSE,
                     outfile1="methyl_dmsites.txt",
                     outfile2="methyl_dmgenes.txt") {
    message('... det_dmsg() ...')
    sample_list <- getSampleID(mrobj)
    treatment_list <- getTreatment(mrobj)
    genes <- genome_ann$gene
    nbtreatments <- length(unique(treatment_list))
    if (nbtreatments < 2) {
        stop("WARNING: det_dmsg() requires input data from at least two ",
             "treatments.")
    }

# If mrobj consists of multiple treatments, compare corresponding samples:
    unique_treatment_list <- unique(treatment_list)
    pairs <- combn(unique_treatment_list, 2, simplify=FALSE)
    dmsites.gr <- lapply(pairs, function(pair) {
        pair_samples <- list(sample_list[pair[1]+1],sample_list[pair[2]+1])
        pair_treatments <- c(pair[1],pair[2])
        pair_mrobj <- reorganize(mrobj,
                                 sample.ids=pair_samples,
                                 treatment=pair_treatments
                                )
        meth <- unite(pair_mrobj,destrand=destrand)
        meth@treatment=c(0,1)
        pairname <- paste(sample_list[pair[1]+1],
                          sample_list[pair[2]+1],sep=".vs.")
        message(paste("... comparison: ",pairname," ...",sep=""))
        pairdiff <- calculateDiffMeth(meth,mc.cores=mc.cores)
        difsites <- getMethylDiff(pairdiff,difference=threshold,qvalue=qvalue)
        gr <- as(difsites,"GRanges")
        if (length(gr) > 0) {
            S4Vectors::mcols(gr)$comparison <- pairname
        }
        message("... done ...")
        return(gr)
       }
       )
    if (length(dmsites.gr) == 0) {
        message("No differentially methylated sites are found.")
        return(list('dmgenes' = GRanges(),
                    'dmsites' = GRanges()))
    }
    if (outfile1 != '') {
        dmsites <- unlist(GRangesList(unlist(dmsites.gr)))
        dmsites$qvalue <- round(dmsites$qvalue,3)
        dmsites$meth.diff <- round(dmsites$meth.diff,2)
        dmsites.df <- BiocGenerics::as.data.frame(dmsites)
        write.table(dmsites.df,file=outfile1,sep='\t',row.names=FALSE,quote=FALSE)
    }

    dmgenes.gr <- lapply(seq_along(pairs), function(i) {
        gr <- subsetByOverlaps(genes,dmsites.gr[[i]])
        pairname <- paste(sample_list[pairs[[i]][1]+1],
                          sample_list[pairs[[i]][2]+1],sep=".vs.")
        if (length(gr) > 0) {
            S4Vectors::mcols(gr)$comparison <- pairname
        }
        return(gr)
       }
       )
    if (length(dmgenes.gr) == 0) {
        message("No differentially methylated genes are found.")
        return(list('dmgenes' = GRanges(),
                    'dmsites' = dmsites.gr))
    }
    if (outfile2 != '') {
        dmgenes <- unlist(GRangesList(unlist(dmgenes.gr)))
        dmgenes.df <- BiocGenerics::as.data.frame(dmgenes)
        write.table(dmgenes.df,file=outfile2,sep='\t',row.names=FALSE,quote=FALSE)
    }

    message('... det_dmsg() finished ...')
    return(list('dmgenes' = dmgenes.gr,
                'dmsites' = dmsites.gr))
}
