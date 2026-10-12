# Visualizing piecewise linear neural networks

- Source: <https://blog.janestreet.com/visualizing-piecewise-linear-neural-networks/>
- Published: 2024-07-22
- Kind: blog post

## Summary

- A researcher visualizes how networks of linear layers and ReLU-style activations compute
  continuous piecewise-linear functions, and so cannot represent discontinuous ones.
- With two inputs, each first-layer neuron draws a line across the plane; the regions between
  lines correspond to activation patterns, and only 37 of the 256 patterns of an 8-neuron
  layer are feasible in two dimensions; the arrangement is a polyhedral complex.
- Later layers draw lines that are straight inside each parent region and bend at its
  boundaries; regions are computed by testing every activation pattern in every parent
  region for feasibility with linear constraints.
- A network trained to reproduce the Jane Street rings logo grows circular structure by the
  third layer; an animation shows untrained weights cutting the plane into few regions and
  trained weights into many.
- The networks actually use LeakyReLU(0.02), because small plain-ReLU networks get stuck in
  local minima.

## Relevance to us

- None: we do no neural-network modelling, and the post is an interpretability
  visualization rather than a tool or technique for our stack.
- **Action:** none.

Tags: `ml`, `education`
