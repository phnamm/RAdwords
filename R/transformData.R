#' @title Transform data into R dataframe
#' 
#' @description Transforms the csv data file received from the Adwords API into a dataframe. Moreover the variables are converted into suitable formats.
#'  The function is used inside \code{\link{getData}} and parameters are set automatically.
#' 
#' @param data Raw csv data from Adwords API.
#' @param report Report type.
#' @param apiVersion set automatically by \code{\link{getData}}. Supported are 201702, 201708, 201710. Defaults to 201710.
#' 
#' @importFrom utils read.csv read.csv2
#' @export
#' 
#' @return Dataframe with the Adwords Data.
transformData <- function(data,
                          report = reportType,
                          apiVersion = "201710"){
  # Transforms the csv into a dataframe. Moreover the variables are converted into suitable formats.
  #
  # Args:
  #   data: csv from Adwords Api
  #   report: Report type
  #
  # Returns:
  #   R Dataframe
  data <- read.csv2(text=data,sep=",",header=F)[-1,]#textConnection(data)
  data <- as.data.frame(data)
  #Rename columns
  for(i in 1:ncol(data)){
    names(data)[i] <- as.character(data[1,i])
  }
  
  if(ncol(data)==1){
    variableName <- names(data)
    #eliminate row with total values
    if(nrow(data)>0){
      if(data[nrow(data), 1] == "Total"){
          data <- as.data.frame(data[2:(nrow(data)-1),1])
      } else {
          data <- as.data.frame(data[2:nrow(data), 1])
      }
    }
    names(data) <- variableName
  }
  else if(ncol(data)>1) {
    #eliminate row with names
    data <- data[-1,]
    #eliminate row with total values
    if(nrow(data)>0){
      if(data[nrow(data), 1] == "Total"){
        data <- data[-nrow(data), ]
      }
    }
  }

  #change data format of variables
  if("Day" %in% colnames(data)){
    data$Day <- as.Date(data$Day)
  }
  #get metrics for requested report
  report <- gsub('_','-',report)
  report <- tolower(report)
  switch(apiVersion,
         "201702" = reportType <- read.csv(paste(system.file(package="RAdwords"),'/extdata/api201702/',report,'.csv',sep=''), sep = ',', encoding = "UTF-8"),
         "201708" = reportType <- read.csv(paste(system.file(package="RAdwords"),'/extdata/api201708/',report,'.csv',sep=''), sep = ',', encoding = "UTF-8"),
         "201710" = reportType <- read.csv(paste(system.file(package="RAdwords"),'/extdata/api201710/',report,'.csv',sep=''), sep = ',', encoding = "UTF-8")
  )
#   else if (apiVersion=="201502"){
#     report <- gsub('_','-',report)
#     report <- tolower(report)
#     reportType <- read.csv(paste(system.file(package="RAdwords"),'/extdata/api201502/',report,'.csv',sep=''), sep = ',', encoding = "UTF-8")
#   }
  #transform factor into character
  i <- sapply(data, is.factor)
  data[i] <- lapply(data[i], as.character)
  #elimitate % in numeric data (Type=Double) however ignore % in non-double variables like ad text
  #and convert percentage values into numeric data
  #define double variables
  Type <- NULL # pass note in R CMD check
  doubleVar <- as.character(subset(reportType, Type == 'Double')$Display.Name)
  #find variables containing %
  perVar <- as.numeric(grep("%",data))
  perVar <- names(data)[perVar]
  #transform variable of type double which contain %
  for(var in doubleVar){
    if(var %in% colnames(data) && var %in% perVar){
      data[, var] <- gsub("%|<|>", "", data[, var])
      data[,var] <- as.numeric(data[,var])/100 
    }
  }
#   perVar <- as.numeric(grep("%",data))
#   #kill % and divide by 100
#   for(i in perVar){
#     data[,i] <- sub("%","",data[,i])
#     data[,i] <- as.numeric(data[,i])/100 
#   }
  Behavior = NULL
  #eliminate ',' thousend separater in data and convert values into numeric data
  metricVar <- as.character(subset(reportType, Behavior == 'Metric')$Display.Name)
  for(var in metricVar){
    if(var %in% colnames(data)){
      data[,var] <- as.character(data[,var])
      data[,var] <- gsub(',','',data[,var])#kill all commas
      data[,var] <- as.numeric(data[,var])
    }
  }
  #since v201409 returnMoneyInMicros is deprecated, convert all monetary values
  Type <- NULL
  monetaryVar <- as.character(subset(reportType, Type == "Money")$Display.Name)
  for (var in monetaryVar) {
    if (var %in% colnames(data)) {
      data[,var] <- as.character(data[,var]) #Variables like Max. CPC are not recognized as metric in previous task since their "Behavior" is "Attribute". Hence convert all "Money" metrics in numeric again.
      data[,var] <- suppressWarnings(as.numeric(data[,var]))
      data[, var] <- data[, var] / 1000000 #convert into micros
    }
  }
  #eliminate " " spaces in column names
  names(data) <- gsub(" ","",names(data))
  data
}