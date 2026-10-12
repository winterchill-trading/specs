# L2 Regularization and Batch Norm

- Source: <https://blog.janestreet.com/l2-regularization-and-batch-norm/>
- Published: 2019-01-29
- Kind: blog post

## Summary

- A Jane Street researcher explains that in convolutional nets trained with SGD, an L2
  penalty on layers followed by batch norm stops acting as a regularizer.
- Batch norm makes the output invariant to the scale of the preceding weights, so shrinking
  them changes nothing and gives no gradient pressure favoring important weights.
- Instead, weight scale controls step size: gradients scale inversely with weight magnitude,
  so relative step size falls with the square of the scale.
- Without a penalty, weights random-walk outward and the effective learning rate decays too
  fast; L2 keeps the scale at an equilibrium and so acts as adaptive learning-rate control.
- Experiment: ResNet-20 on CIFAR-10 in TensorFlow. Dropping L2 from the conv layers cut
  accuracy from about 91% to 89.5%; rescaling conv gradients by the squared weight norm
  (plus a piecewise-linear correction) restored baseline accuracy without the penalty.
- A side effect: batch norm moving averages lag exponentially growing weights at inference,
  fixed by shortening the averaging window (decay 0.997 to 0.98).
- The analysis does not cover layers after the last batch norm or optimizers like Adam.

## Relevance to us

- Weak relevance: deep learning optimization detail. We train no models in
  [mm-core](../../../repos/mm-core.md) or [market-data](../../../repos/market-data.md).
- **Action:** none.

Tags: `ml`
