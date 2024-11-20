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

enumerated <- sort_and_dedupe(read.csv("../data/enumerated.csv"), "input")

ggplot(enumerated) +
  geom_point(aes(x = input, y = magic), shape = ".", alpha = 0.8) +
  guides(color = "none") + ylim(1.5965e+09, 1.5985e+09)


ggplot(enumerated[enumerated[,"input"] > 2e-08, ], aes(x = magic, y = error)) +
  geom_bin2d(bins = 80) + guides(fill = "none")
