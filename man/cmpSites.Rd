% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cmpSites.R
\name{cmpSites}
\alias{cmpSites}
\title{cmpSites()
This function compares (potential) methylation sites between two samples.}
\usage{
cmpSites(sample1hsm, sample1scd, sample1label, sample2hsm, sample2scd,
  sample2label, nbrpms)
}
\arguments{
\item{sample1hsm}{A methylRaw object for hsm sites of sample 1.}

\item{sample1scd}{A methylRaw object for scd sites of sample 1.}

\item{sample1label}{A string serving as a label for sample 1.}

\item{sample2hsm}{A methylRaw object for hsm sites of sample 2.}

\item{sample2scd}{A methylRaw object for scd sites of stample 2.}

\item{sample2label}{A string serving as a label for sample 2.}

\item{nbrpms}{Integer representing the number of potential methylation
sites in the genome; typically derived from the input *.par file.}
}
\value{
A list of data frames containing data on unique and common
  sites comparing the two samples.
}
\description{
cmpSites()
This function compares (potential) methylation sites between two samples.
}
\examples{
  mydatf <- system.file("extdata","Am.dat",package="BWASPR")
  myparf <- system.file("extdata","Am.par",package="BWASPR")
  myfiles <- setup_BWASPR(datafile=mydatf,parfile=myparf)
  nbrpms  <- as.numeric(myfiles$parameters[
    myfiles$parameters$Variable == "TOTALNBRPMSITES",2])
  AmHEhsm <- mcalls2mkobj(myfiles$datafiles,species="Am",study="HE",
                          type="CpGhsm", mincov=1,assembly="Amel-4.5")
  AmHEscd <- mcalls2mkobj(myfiles$datafiles,species="Am",study="HE",
                          type="CpGscd", mincov=1,assembly="Amel-4.5")
  s1hsm <- methylKit::getData(AmHEhsm[[1]])
  s1scd <- methylKit::getData(AmHEscd[[1]])
  s2hsm <- methylKit::getData(AmHEhsm[[2]])
  s2scd <- methylKit::getData(AmHEscd[[2]])
  mydflist <- cmpSites(s1hsm,s1scd,"Am_HE_fr",s2hsm,s2scd,"Am_HE_rn",nbrpms)

}
