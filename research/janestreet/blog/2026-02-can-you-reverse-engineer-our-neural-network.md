# Can you reverse engineer our neural network?

- Source: <https://blog.janestreet.com/can-you-reverse-engineer-our-neural-network/>
- Published: 2026-02-24
- Kind: blog post

## Summary

- Spoiler write-up of an ML puzzle published a year earlier. Unlike black-box
  capture-the-flag puzzles, solvers got the full PyTorch model and weights and had to use
  mechanistic interpretability, a situation the firm's researchers sometimes face.
- The network outputs 0 for nearly all inputs and was built so that searching backward
  from a nonzero output (for example by backpropagation) could not work. The difficulty
  turned out well calibrated.
- The walkthrough follows one solver. All weights were integers, so the network was hand
  designed, not trained.
- The last two layers check that a 16-byte vector equals a constant held in the biases:
  three shifted ReLU copies weighted 1, -2, 1 sum to one only on exact equality, and a bias
  of -15 requires all 16 bytes to match.
- Treating the remaining roughly 2,500 linear layers as an integer linear program (one
  integer per ReLU sign) did not terminate.
- Graph reductions on the integer network (merge single-input identity nodes, skip ReLUs
  whose inputs are always nonnegative, merge neurons with identical inputs, collapse
  repeated pass-through patterns) shrank it from about 2 million nodes to 75,000.
- Bound propagation then gave tight ranges, and a SAT encoding of 200,000 variables
  reduced to 20,000, but that irreducible core was still too hard.
- Reasoning about how a solvable puzzle would be built suggested an irreversible function.
  Layer widths repeated 32 times with period 48, a hash-like structure; probing
  activations against reference implementations matched MD5.
- The solver mapped every neuron to MD5 variables and found an unintended bug: the
  input-length encoding breaks for inputs of 32 bytes or more. Exploiting it led nowhere.
- The intended route was to brute-force the target hash using hints that the answer is two
  lowercase English words joined by a space; the first attempt failed only because the word
  list was too small.
- Building it took a parallel carry adder in about 20 layers to do MD5's modular addition.
  A new puzzle asks solvers to restore the order of a network's shuffled layers.

## Relevance to us

- Puzzle and recruiting post; it does not touch our repos.
- **Action:** none.

Tags: `ml`, `education`, `hiring`
