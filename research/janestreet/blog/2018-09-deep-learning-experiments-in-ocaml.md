# Deep learning experiments in OCaml

- Source: <https://blog.janestreet.com/deep-learning-experiments-in-ocaml/>
- Published: 2018-09-20
- Kind: blog post

## Summary

- Write-up of a London machine learning seminar that reproduced classic deep learning
  results in OCaml rather than Python, training on GPU through TensorFlow.
- The tensorflow-ocaml bindings expose a functional API: VGG-19 is a pipeline of repeated
  conv-and-ReLU blocks with max pooling, and an LSTM cell is a staged closure over its
  weight and bias variables.
- Graph nodes carry a phantom polymorphic-variant type for the element kind, so operations
  state which kinds they accept (square root on floats or doubles, comparisons returning
  booleans) and misuse fails at compile time.
- The typed wrappers are generated automatically from TensorFlow's operation description
  file; shapes and dimensions are deliberately not tracked in types.
- Neural style transfer with a pretrained VGG-19: match high-level features of the content
  image and position-free low-level feature statistics of the style image.
- A character-level two-layer LSTM trained on the Base sources (about 27k lines) produced
  OCaml-looking text that does not compile but gets comments and structure right.
- Drawbacks: a thin ML ecosystem, few learning resources, and shape errors reported
  without useful locations (eager mode might help).
- Benefits: type errors surface before hours of training, and typed functional
  representations fit neural networks, especially recurrent ones, naturally.

## Relevance to us

- No ML in our stack. The phantom-type idea is already covered by distinct
  `Fixed_decimal.Make ()` types in [fixed-decimal](../../../repos/fixed-decimal.md).
  **Action:** none.

Tags: `ml`, `ocaml-practice`, `python-interop`
