# L2 Regularization and Batch Norm

- Source: <https://blog.janestreet.com/l2-regularization-and-batch-norm/>
- Published: 2019-01-29
- Kind: blog post

## Summary

- A Jane Street researcher explains a widely overlooked interaction: in convolutional nets
  trained with SGD, an L2 penalty on layers followed by batch norm stops regularizing.
- Recap: L2 adds the scaled sum of squared weights to the loss, so each step also decays
  weights toward zero; the usual story is that useful weights recover while noise-fitting
  weights stay small, or in Bayesian terms a prior favoring smoother models.
- Batch norm normalizes per-channel activations to zero mean and unit variance, making the
  output nearly invariant to the scale of preceding weights; why it helps is still debated.
- Consequence: shrinking those weights changes nothing, the gradient direction is
  scale-invariant, and there is no pressure favoring important weights, so the
  regularizing mechanism disappears.
- New role: gradients scale inversely with weight magnitude, so relative step size falls
  with the square of the scale; without a penalty, weights random-walk outward and the
  effective learning rate decays. L2 holds the scale at an equilibrium.
- Experiment on ResNet-20 and CIFAR-10 (TensorFlow 1.11, 150 epochs in three learning-rate
  stages): removing L2 from conv layers dropped accuracy from about 91% to 89.5%, with
  faster weight growth and shrinking relative steps; the gap showed both more underfitting
  and more overfitting.
- Rescaling conv-layer gradients by the squared weight norm, plus a piecewise-linear
  correction matching the baseline's own drift, recovered baseline accuracy with no L2.
- Side effect: batch norm moving averages could not track exponentially growing weights at
  inference; shortening the window (decay 0.997 to 0.98) fixed early-epoch accuracy.
- Caveats: the analysis excludes layers after the last batch norm and optimizers like Adam,
  where weight decay and L2 differ.

## Relevance to us

- No relevant insight: deep learning optimization; we train no models.
  **Action:** none.

Tags: `ml`
