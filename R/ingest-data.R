sort_and_dedupe <- function(df, column_name) {
  # Check if the column exists in the dataframe
  if (!column_name %in% names(df)) {
    stop(paste("Column", column_name, "not found in the dataframe"))
  }
  
  # Sort the dataframe based on the specified column
  df_sorted <- df[order(df[[column_name]]), ]
  
  # Remove duplicates based on the specified column
  df_deduped <- df_sorted[!duplicated(df_sorted[[column_name]]), ]
  
  return(df_deduped)
}

approximated <- sort_and_dedupe(read.csv("../data/approximated.csv"), "input")
enumerated <- sort_and_dedupe(read.csv("../data/enumerated.csv"), "input")

## these will have duplicate floats by design
sliced <- read.csv("../data/sliced.csv")
sliced <- sliced[!duplicated(sliced[,c("input", "magic")]), ]

deconstructed <- read.csv("../data/deconstructed.csv")



