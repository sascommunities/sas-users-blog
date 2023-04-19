# Empirical Mode Decomposition in SAS/IML

This repository contains a SAS code for analyzing the West Texas Intermediate (WTI) crude oil prices. The analysis includes importing the data, preprocessing, Empirical Mode Decomposition (EMD), and time series modeling.

## Getting Started

These instructions will help you understand the code and the analysis performed on the WTI crude oil prices dataset.

### Prerequisites

- SAS Software
- Internet access to download the dataset from the provided URL.

### Overview of the Analysis

1. Import the WTI crude oil prices dataset from the specified URL into a SAS dataset.
2. Prprocess the Data
4. Perform Empirical Mode Decomposition (EMD) to obtain Intrinsic Mode Functions (IMFs) and residual.
5. Split the data into temporally contiguous training and test sets based on a specified date.
6. Perform time series modeling using the `proc tsmodel` procedure.

### Running the Code

Open the provided SAS code in your SAS environment and execute the script to perform the analysis.

### Output

- A plot of the oil price time series with categorized observations.
- IMFs of West Texas Intermediate Crude Prices plot.
- Fit statistics table for the time series model.
- A plot of predicted and actual values of IMF1 with 95% confidence limits.