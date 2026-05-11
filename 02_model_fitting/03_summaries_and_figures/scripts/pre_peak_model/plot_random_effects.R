# Required libraries
library(here)
library(brms)

################### DEVIATION FROM POPULATION-LEVEL EFFECTS ####################
################### AT SPATIAL_CLUSTER LEVEL ###################################

# Load the fitted Bayesian model

fit <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","model_3.rds"))

# Extract spatial-cluster-level random effects.
# These values represent each spatial cluster's deviation from the
# population-level effect estimated by the model

cluster_dev <- ranef(fit)$spatial_cluster

# Convert the random effects array to a data frame and preserve the
# spatial cluster names as an explicit column

cluster_dev_df <- as.data.frame(cluster_dev)
cluster_dev_df$spatial_cluster <- rownames(cluster_dev)

# View the output table in R

cluster_dev_df