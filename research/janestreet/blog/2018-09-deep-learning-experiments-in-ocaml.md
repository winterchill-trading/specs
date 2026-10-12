# Deep learning experiments in OCaml

- Source: <https://blog.janestreet.com/deep-learning-experiments-in-ocaml/>
- Published: 2018-09-20
- Kind: blog post

## Summary

- Write-up of a London machine learning seminar that reproduced classic deep learning
  results in OCaml instead of Python, training on GPU through TensorFlow bindings.
- The tensorflow-ocaml bindings offer a functional combinator API: VGG-19 is a pipeline of
  conv/pool blocks, and an LSTM cell is a staged closure over its weight variables.
- Graph nodes carry a phantom polymorphic-variant type for element kind, so applying a
  float-only op such as square root to a boolean tensor fails at compile time.
- Those typed signatures are generated automatically from TensorFlow's operation
  description file; tensor shapes are not tracked in the types.
- Demos: neural style transfer with a pretrained VGG-19, and a two-layer character LSTM
  trained on the Base sources (27k lines) that emits plausible-looking but non-compiling
  OCaml.
- Downsides: a thin ML ecosystem, few learning resources, and shape errors without useful
  locations. Upside: type errors surface before hours of training, not after.

## Relevance to us

- Weak relevance: no ML in our stack. The phantom-type trick for constraining operations
  echoes our distinct `Fixed_decimal.Make ()` types for price, size and USD in
  [fixed-decimal](../../../repos/fixed-decimal.md), which already cover that idea.
- **Action:** none.

Tags: `ml`, `ocaml-practice`, `python-interop`
