---
title: "mikropml: User-Friendly R Package for Robust Machine Learning Pipelines"
output: 
  rmarkdown::html_vignette:
    keep_md: true
tags:
  - R
  - machine learning
  - regression
  - decision trees
  - random forest
  - xgboost
  - microbiology
author: Begüm D. Topçuoğlu, Zena Lapp, Kelly L. Sovacool, Evan Snitkin, Jenna Wiens, Patrick D. Schloss
authors:
  - name: Begüm D. Topçuoğlu^[co-first author]
    orcid: 0000-0003-3140-537X
    affiliation: "3, 4"
  - name: Zena Lapp^[co-first author]
    orcid: 0000-0003-4674-2176
    affiliation: 1
  - name: Kelly L. Sovacool^[co-first author]
    orcid: 0000-0003-3283-829X
    affiliation: 1
  - name: Evan Snitkin
    orcid: 0000-0001-8409-278X
    affiliation: "3, 5"
  - name: Jenna Wiens
    orcid: 0000-0002-1057-7722
    affiliation: 2
  - name: Patrick D. Schloss^[corresponding author]
    orcid: 0000-0002-6935-4275
    affiliation: 3
affiliations:
  - name: Department of Computational Medicine & Bioinformatics, University of Michigan
    index: 1
  - name: Department of Electrical Engineering & Computer Science, University of Michigan
    index: 2
  - name: Department of Microbiology & Immunology, University of Michigan
    index: 3
  - name: Exploratory Science Center, Merck & Co., Inc., Cambridge, Massachusetts, USA.
    index: 4
  - name: Department of Internal Medicine/Division of Infectious Diseases, University of Michigan
    index: 5
date: 2020
bibliography: paper.bib
vignette: >
  %\VignetteIndexEntry{mikropml paper}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---




# Summary

Machine learning (ML) for classification and prediction based on a set of features is used to make decisions in healthcare, economics, criminal justice and more. 
However, implementing a robust ML pipeline can be time-consuming, confusing, and difficult. 
Here, we present [`mikropml`](http://www.schlosslab.org/mikropml/) (prononced "meek-ROPE em el"), an easy-to-use R package that implements robust ML pipelines using regression, support vector machines, decision trees, random forest, or gradient-boosted trees.
The package is available on [GitHub](https://github.com/SchlossLab/mikropml/) and CRAN. 

# Statement of need

A robust machine learning (ML) pipeline requires data pre-processing, cross-validation, testing, model evaluation, and often interpretation of why the model makes particular predictions. 
Performing these steps using the correct methodology is extremely important, as failure to implement them can result in incorrect and misleading results [@teschendorff_avoiding_2019; @wiens_no_2019]. 

Supervised ML is widely used to recognize patterns in large datasets and to make predictions about outcomes of interest. 
Several packages including `caret` [@kuhn_building_2008] and `tidymodels` [@kuhn_tidymodels_2020] in R and `scikitlearn` [@pedregosa_scikit-learn_2011] in Python allow scientists to train ML models with a variety of algorithms. 
While these packages provide all of the tools necessary for each ML step, they do not implement a complete robust ML pipeline according to best practices in the literature. 
This, paired with the vast number of options available, makes it difficult for non-experts to easily perform robust ML analyses using these packages. 
Furthermore, these packages do not offer a unified way to identify features that contribute to improved model performance.

To enable a broader range of researchers to perform robust ML analyses, we created [`mikropml`](https://github.com/SchlossLab/mikropml/), an easy-to-use package in R [@r_core_team_r_2020] that implements the ML framework created by Topçuoğlu _et al._ [@topcuoglu_framework_2020]. 
`mikropml` leverages the `caret` package to support several ML algorithms:
linear regression, logistic regression, support vector machine with a radial basis kernel, decision tree, random forest, and gradient boosted trees.
It incorporates best practices in ML training, testing, and model evaluation [@topcuoglu_framework_2020;@teschendorff_avoiding_2019].
Furthermore, it provides data preprocessing steps based on the FIDDLE (FlexIble Data-Driven pipeLinE) framework outlined in Tang _et al._ [@tang_democratizing_2020] 
and post-training permutation importance steps to measure the importance of each feature in the model [@breiman_random_2001; @fisher_all_2018].

The framework implemented in `mikropml` is generalizable to perform ML on datasets from many different fields.
It has already been applied to microbiome data to categorize patients with colorectal cancer [@topcuoglu_framework_2020], 
to identify differences in genomic and clinical features associated with bacterial infections [@lapp_machine_2020], 
and to predict gender-based biases in academic publishing [@hagan_women_2020]. 

# mikropml package

The `mikropml` package includes functions to preprocess the data, train ML models, and quantify feature importance. 
We also provide [vignettes](http://www.schlosslab.org/mikropml/articles/index.html) 
and an [example snakemake workflow](https://github.com/SchlossLab/mikropml-snakemake-workflow) [@koster_snakemakescalable_2012] 
to showcase how to run an ideal ML pipeline with multiple different train/test data splits.
The results can be visualized using helper functions that use `ggplot2` [@wickham_ggplot2_2016].

## Preprocessing data

We provide a function `preprocess_data()` to preprocess features using several different functions from the `caret` package.
The `preprocess_data()` function takes continuous and categorical data, re-factors categorical data into binary features, and provides options to normalize continuous data, remove features with near-zero variance, and keep only one instance of perfectly correlated features. 
We set the default options based on best practices implemented in FIDDLE [@tang_democratizing_2020]. 
More details on how to use `preprocess_data()` can be found in the accompanying [vignette](http://www.schlosslab.org/mikropml/articles/preprocess.html).

## Running ML

The main function in mikropml, `run_ml()`, minimally takes in the model choice and a data frame with an outcome column and remaining columns as categorical or continuous features.
For model choice, `mikropml` currently supports logistic and linear regression [@friedman_regularization_2010], support vector machine with a radial basis kernel [@karatzoglou_kernlab_2004], decision trees [@therneau_rpart_2019], random forest [@liaw_classication_2002], and gradient-boosted trees [@chen_xgboost_2020]. 
`run_ml()` randomly splits the data into train and test sets while maintaining the distribution of the outcomes found in the full dataset. 
It also provides the option to split the data into train and test sets based on categorical variables (e.g. batch, geographic location, etc.).
`mikropml` uses the `caret` package [@kuhn_building_2008] to train and evaluate the model, and optionally quantifies feature importance.
The output includes the best model built based on tuning hyperparameters in an internal and repeated cross-validation step, model evaluation metrics, and optional feature importances (Figure 1). 
The quantification of feature importance using permutation allows the calculation of the decrease in the model's prediction performance after breaking the relationship between the feature and the true outcome, and is thus particularly useful for model interpretation [@topcuoglu_framework_2020]. 
Our [introductory vignette](http://www.schlosslab.org/mikropml/articles/introduction.html) contains a comprehensive tutorial on how to use `run_ml()`.

![mikropml pipeline](mikRopML-pipeline.png){width=100%}

## Ideal workflow for running mikropml with many different train/test splits

To investigate the variation in model performance depending on the train and test set used [@topcuoglu_framework_2020; @lapp_machine_2020], 
we provide examples of how to run the `run_ml()` function many times with different train/test splits 
and how to get summary information about model performance on [a local computer](http://www.schlosslab.org/mikropml/articles/parallel.html) or on a high-performance computing cluster using a [snakemake workflow](https://github.com/SchlossLab/mikropml-snakemake-workflow). 

## Tuning & visualization

One particularly important aspect of ML is hyperparameter tuning. 
Practitioners must explore a range of hyperparameter possibilities to pick the ideal value for the model and dataset.
Therefore, we provide a function `plot_hp_performance()` to plot the cross-validation performance metric of models built using different train/test splits to evaluate if we are exhausting our hyperparameter search range to pick the ideal one. 
We also provide summary plots of test performance metrics for the many train/test splits with different models using `plot_model_performance()`.
Examples are described in the accompanying [vignette on hyperparameter tuning](http://www.schlosslab.org/mikropml/articles/tuning.html).

## Dependencies

mikropml is written in R [@r_core_team_r_2020] and depends on several packages: `dplyr` [@wickham_dplyr_2020], `rlang` [@henry_rlang_2020] and `caret` [@kuhn_building_2008].
The ML algorithms supported by `mikropml` require:
`glmnet` [@friedman_regularization_2010], `e1071` [@meyer_e1071_2020], and `MLmetrics` [@yan_mlmetrics_2016] for logistic regression, `rpart2` [@therneau_rpart_2019] for decision trees, `randomForest` [@liaw_classication_2002] for random forest, `xgboost` [@chen_xgboost_2020] for xgboost, and `kernlab` [@karatzoglou_kernlab_2004] for support vector machines. 
We also allow for parallelization of cross-validation and other steps using the `foreach`, `doFuture`, `future.apply`, and `future` packages [@bengtsson_futureapply_2020].
Finally, we use `ggplot2` for plotting [@wickham_ggplot2_2016].

# Acknowledgments

We thank members of the Schloss Lab who participated in code clubs related to the initial development of the pipeline.

# Funding

Salary support for PDS came from NIH grant 1R01CA215574.
KLS received support from the NIH Training Program in Bioinformatics (T32 GM070449).
ZL received support from the National Science Foundation Graduate Research Fellowship Program under Grant No. DGE 1256260. 
Any opinions, findings, and conclusions or recommendations expressed in this material are those of the authors and do not necessarily reflect the views of the National Science Foundation.

# Author contributions

BT, ZL, and KLS conceptualized the study and created the package.
BT, ZL, JW, and PDS developed methodology. 
PDS, ES, and JW supervised the project. 
BT, ZL, and KLS wrote the original draft. 
All authors reviewed and edited the manuscript.

# Conflicts of interest

None.

# References
