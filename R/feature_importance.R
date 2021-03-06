#' Get feature importance using permutation method
#'
#' Calculates feature importance using a trained model and test data. Requires the `future.apply` package.
#'
#' @param train_data Training data: dataframe of outcome and features.
#' @inheritParams run_ml
#' @inheritParams calc_perf_metrics
#'
#' @return Dataframe with performance metrics for when each feature (or group of correlated features; `names`) is permuted (`perf_metric`), and differences between test performance metric and permuted performance metric (`perf_metric_diff`). The performance metric name (`perf_metric_name`) and seed (`seed`) are also returned.
#'
#' @examples
#' \dontrun{
#' results <- run_ml(otu_small, "glmnet", kfold = 2, cv_times = 2)
#' names(results$trained_model$trainingData)[1] <- "dx"
#' get_feature_importance(results$trained_model, results$trained_model$trainingData, results$test_data,
#'   "dx",
#'   multiClassSummary, "AUC",
#'   class_probs = TRUE, method = "glmnet"
#' )
#' }
#'
#' @export
#' @author Begüm Topçuoğlu, \email{topcuoglu.begum@@gmail.com}
#' @author Zena Lapp, \email{zenalapp@@umich.edu}
get_feature_importance <- function(trained_model, train_data, test_data, outcome_colname, perf_metric_function, perf_metric_name, class_probs, method, seed = NA, corr_thresh = 1) {
  abort_packages_not_installed("future.apply")

  # get outcome and features
  split_dat <- split_outcome_features(train_data, outcome_colname)
  outcome <- split_dat$outcome
  features <- split_dat$features

  corr_mat <- get_corr_feats(features, corr_thresh = corr_thresh)
  corr_mat <- dplyr::select_if(corr_mat, !(names(corr_mat) %in% c("corr")))

  grps <- group_correlated_features(corr_mat, features)

  imps <- future.apply::future_lapply(grps, function(feat) {
    return(find_permuted_perf_metric(
      test_data, trained_model, outcome_colname,
      perf_metric_function, perf_metric_name,
      class_probs, feat, seed
    ))
  }, future.seed = seed) %>%
    dplyr::bind_rows()

  return(as.data.frame(imps) %>%
    dplyr::mutate(
      names = factor(grps),
      method = method,
      perf_metric_name = perf_metric_name,
      seed = seed
    ))
}

#' Get permuted performance metric difference for a single feature (or group of features)
#'
#' Requires the `future.apply` package
#'
#' @param feat feature or group of correlated features to permute
#' @inheritParams run_ml
#' @inheritParams get_feature_importance
#'
#' @return vector of mean permuted auc and mean difference between test and permuted auc
#' @noRd
#' @author Begüm Topçuoğlu, \email{topcuoglu.begum@@gmail.com}
#' @author Zena Lapp, \email{zenalapp@@umich.edu}
#' @author Kelly Sovacool, \email{sovacool@@umich.edu}
#'
find_permuted_perf_metric <- function(test_data, trained_model, outcome_colname, perf_metric_function, perf_metric_name, class_probs, feat, seed) {
  abort_packages_not_installed("future.apply")

  # The code below uses a bunch of base R subsetting that doesn't work with tibbles.
  # We should probably refactor those to use tidyverse functions instead,
  # but for now this is a temporary fix.
  test_data <- as.data.frame(test_data)

  # Calculate the test performance metric for the actual pre-processed held-out data
  test_perf_metric <- calc_perf_metrics(
    test_data,
    trained_model,
    outcome_colname,
    perf_metric_function,
    class_probs
  )[perf_metric_name]
  # permute grouped features together
  fs <- strsplit(feat, "\\|")[[1]]
  # only include ones in the test data split
  fs <- fs[fs %in% colnames(test_data)]
  # get the new performance metric and performance metric differences
  perf_metric_diffs <- future.apply::future_sapply(0:99, function(s) {
    set.seed(s)
    permuted_test_data <- test_data
    if (length(fs) == 1) {
      permuted_test_data[, fs] <- sample(permuted_test_data[, fs])
    } else {
      permuted_test_data[, fs] <- t(sample(data.frame(t(permuted_test_data[, fs]))))
    }
    # Calculate the new performance metric
    new_perf_metric <- calc_perf_metrics(
      permuted_test_data,
      trained_model,
      outcome_colname,
      perf_metric_function,
      class_probs
    )[perf_metric_name]
    # Return how does this feature being permuted effect the performance metric
    return(c(new_perf_metric = new_perf_metric, diff = (test_perf_metric - new_perf_metric)))
  }, future.seed = seed)
  if (!is.na(seed)) set.seed(seed) # must set seed back to its original value
  rownames(perf_metric_diffs) <- gsub("\\..*", "", rownames(perf_metric_diffs))
  perf_metric <- mean(perf_metric_diffs["new_perf_metric", ])
  perf_metric_diff <- mean(perf_metric_diffs["diff", ])
  return(c(perf_metric = perf_metric, perf_metric_diff = perf_metric_diff))
}
