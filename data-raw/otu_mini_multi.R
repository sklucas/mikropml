## code to prepare `otu_mini` dataset
otu_large_multi <- read.delim("data-raw/otu_large_multi.csv", sep = ",")
set.seed(2019)
outcome_colname <- "dx"
kfolds <- 2
otu_mini_multi <- otu_large_multi[, 1:4]
usethis::use_data(otu_mini_multi, overwrite = TRUE)

test_hyperparams <- structure(list(
  param = c(
    "lambda", "lambda", "lambda", "alpha",
    "sigma", "sigma", "C", "C",
    "maxdepth", "maxdepth",
    "nrounds", "gamma", "eta", "max_depth", "colsample_bytree", "min_child_weight", "subsample",
    "mtry", "mtry"
  ),
  value = c(
    "1e-3", "1e-2", "1e-1", "1",
    "0.00000001", "0.0000001", "0.01", "0.1",
    "1", "2",
    "10", "0", "0.01", "1", "0.8", "1", "0.4",
    "1", "2"
  ),
  method = c(
    "glmnet", "glmnet", "glmnet", "glmnet",
    "svmRadial", "svmRadial", "svmRadial", "svmRadial",
    "rpart2", "rpart2",
    "xgbTree", "xgbTree", "xgbTree", "xgbTree", "xgbTree", "xgbTree", "xgbTree",
    "rf", "rf"
  )
),
class = c("spec_tbl_df", "tbl_df", "tbl", "data.frame"), row.names = c(NA, -19L)
)

set.seed(2019)
otu_mini_multi_results1 <- mikropml::run_ml(otu_mini_multi, # use built-in hyperparams
  "glmnet",
  outcome_colname = "dx",
  find_feature_importance = TRUE,
  seed = 2019,
  kfold = 2,
  cv_times = 2,
  group = sample(LETTERS[1:10], nrow(otu_mini_multi), replace = TRUE)
)

hparams_list <- get_hyperparams_from_df(test_hyperparams, "glmnet")
set.seed(2019)
otu_mini_multi_cv2 <- define_cv(otu_mini_multi_results1$trained_model$trainingData,
  "dx",
  hparams_list,
  perf_metric_function = caret::multiClassSummary,
  class_probs = TRUE,
  kfold = 2,
  cv_times = 2,
  group = sample(LETTERS[1:4],
    nrow(otu_mini_results1$trained_model$trainingData),
    replace = TRUE
  )
)

# use built-in hyperparams function for this one
otu_mini_multi_results2 <- mikropml::run_ml(otu_mini_multi,
  "rf",
  outcome_colname = "dx",
  find_feature_importance = FALSE,
  seed = 2019,
  kfold = 2,
  cv_times = 2
)

otu_mini_multi_results4 <- mikropml::run_ml(otu_mini_multi,
  "xgbTree",
  outcome_colname = "dx",
  hyperparameters = get_hyperparams_from_df(test_hyperparams, "xgbTree"),
  find_feature_importance = FALSE,
  seed = 2019,
  kfold = 2,
  cv_times = 2
)

otu_mini_multi_results5 <- mikropml::run_ml(otu_mini_multi,
  "rpart2",
  outcome_colname = "dx",
  find_feature_importance = FALSE,
  seed = 2019,
  kfold = 2,
  cv_times = 2
)