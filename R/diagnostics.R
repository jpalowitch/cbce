diagnostics1 <- function(event){
  e <- parent.frame()
  switch(event,
  "ExtracionLoopBegins" = {
    e$consec_jaccards <- NULL
    e$mean_jaccards <- NULL
    e$consec_sizes <- list(c(length(e$B0$x), length(e$B0$y)))
    e$found_cycle <- NULL
    e$found_break <- NULL
    e$initial_set <- unlist(e$B0)
  }, 
  "AfterUpdate" = {
    consec_jaccard <- jaccard(unlist(e$B0), unlist(e$B1))
    e$consec_jaccards <- c(e$consec_jaccards, consec_jaccard)
    e$mean_jaccards <- c(e$mean_jaccards, mean(e$jaccards))
    e$consec_sizes <- c(e$consec_sizes, list(c(length(e$B1$x), length(e$B1$y))))
    e$found_cycle <- c(e$found_cycle, FALSE)
    e$found_break <- c(e$found_break, FALSE)
  }, 
  "EndOfExtract" = {
    update_info <- list("mean_jaccards" = e$mean_jaccards, 
                        "consec_jaccards" = e$consec_jaccards,
                        "consec_sizes" = e$consec_sizes,
                        "found_cycle" = e$found_cycle,
                        "found_break" = e$found_break)
    list("update_info" = update_info, 
         "initial_set" = e$initial_set,
         "start_time" = e$current_time
         )
  },
  "FoundCycle" = {
    e$found_cycle[e$itCount] <- TRUE
  },
  "FoundBreak" = {
    e$found_break[e$itCount] <- TRUE 
  }, NA)
}