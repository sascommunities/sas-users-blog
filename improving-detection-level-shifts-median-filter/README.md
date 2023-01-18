# Improving the Detection of Level Shifts Using the Median Filter

Time series data is widely used in various fields such as finance, economics, and engineering. One of the key challenges when working with time series data is detecting level shifts. A level shift occurs when the time series' mean or variance changes abruptly. These shifts can significantly impact the analysis and forecasting of the time series and must be detected and handled properly.

One popular method for detecting level shifts is by using an Autoregressive Moving Average (ARMA) time series model. ARMA models are widely used in time series analysis as they combine the autoregressive (AR) and moving average (MA) models to capture both short-term and long-term dependencies in the data. By fitting an ARMA model to the time series data, it is possible to detect level shifts by observing changes in the parameters of the model.

The ARMA model can be represented mathematically as:

$X_t = c + \phi_1 X_{t-1} + \phi_2 X_{t-2} + ... + \phi_p X_{t-p} + \theta_1 \epsilon_{t-1} + \theta_2 \epsilon_{t-2} + ... + \theta_q \epsilon_{t-q} + \epsilon_t$

Where $X_t$ is the time series, $\epsilon_t$ is the white noise, $c$ is a constant, $\phi_i$ and $\theta_i$ are the AR and MA parameters, respectively, and p and q are the order of the AR and MA components.

A level shift can be captured in an ARMA model by adding a dummy variable, which is a binary variable that takes on the value of 1 at the point of the level shift and 0 otherwise. This dummy variable can be multiplied by a scalar parameter, representing the level shift's magnitude. The dummy variable is then included as an explanatory variable in the ARMA model.

The full ARMA model with the dummy variable can be represented mathematically as:

$X_t = c + \phi_1 X_{t-1} + \phi_2 X_{t-2} + ... + \phi_p X_{t-p} + \delta D_t + \theta_1 \epsilon_{t-1} + \theta_2 \epsilon_{t-2} + ... + \theta_q \epsilon_{t-q} + \epsilon_t$

Where $X_t$ is the time series, $\epsilon_t$ is the white noise, $c$ is a constant, $\phi_i$ and $\theta_i$ are the AR and MA parameters, respectively, $D_t$ is the dummy variable, $\delta$ is the magnitude of the level shift at time t, p and q are the order of the AR and MA parts.

Note that we need to identify the time point t where the level shift occurs. This can be done by visual inspection, statistical estimation, and testing. In some cases automated estimation techniques may fail to detect level shifts and other approaches may be required to improve classification. One approach to improving the correct classification of level shifts in the case of high error variation is to use a windowed median filter on the original series $X_t$. This can be implemented using the following formula:

$$ Y_t = median(X_{t-k}, X_{t-k+1}, ..., X_{t-1}, X_{t}, X_{t+1}, ..., X_{t+k}) $$

Where $Y_t$ is the filtered time series, $X_t$ is the original time series, and $k$ is the window size. The windowed median filter replaces each value in the original time series with the median value of the surrounding values within a given window. This can help to smooth out variations in the time series and make it easier to detect level shifts.
