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


sliced <- read.csv("../data/sliced.csv")
sliced <- sort_and_dedupe(sliced, "input")
enumerated <- read.csv("../data/enumerated.csv")
enumerated <- sort_and_dedupe(enumerated, "input")
deconstructed <- read.csv("../data/deconstructed.csv")
deconstructed <- sort_and_dedupe(deconstructed, "input")
approximated <- read.csv("../data/approximated.csv")
approximated <- sort_and_dedupe(approximated, "input")

