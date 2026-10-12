# Of Pythons and Camels

- Source: <https://blog.janestreet.com/of-pythons-and-camels/>
- Published: 2019-07-09
- Kind: blog post

## Summary

- Part of a series on machine learning in OCaml, following the PyTorch transfer learning
  tutorial but using the ocaml-torch bindings.
- Transfer learning reuses a network trained on a large generic dataset (ImageNet) for a
  small related task, cutting compute and data needs.
- Dataset: 249 python and 822 camel images from Open Images V5.
- Two options are described: fine-tune the whole pretrained model with a new final layer, or
  freeze it as a feature extractor and train only a classifier on its outputs; the post uses
  the second, with ResNet-18.
- Steps: load images into NCHW tensors, load pretrained weights into a frozen variable
  store, precompute the 512-value activations once, then train a linear classifier with SGD
  and cross-entropy for 20 epochs. It runs in under a minute on a laptop CPU, against weeks
  of GPU time for the original training, and reaches near 100 percent test accuracy.
- Baseline: simply comparing ImageNet's own python and camel class scores already exceeds 98
  percent accuracy.
- Harder task: separating one-humped from two-humped camels, which ImageNet lumps together,
  with only 165 and 70 training images; the frozen-feature approach still gets above 90
  percent, because lower layers learn generic features.

## Relevance to us

- Image-classification ML in OCaml; our stack has no ML models and none are planned.
  **Action:** none.

Tags: `ml`, `python-interop`
