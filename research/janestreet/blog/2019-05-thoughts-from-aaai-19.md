# Thoughts from AAAI 2019

- Source: <https://blog.janestreet.com/thoughts-from-aaai-19/>
- Published: 2019-05-13
- Kind: blog post

## Summary

- A conference report from Jane Street researchers at AAAI 2019, reflecting growing interest
  in machine learning at the firm.
- Interpretability: activation-based explanation methods (gradient visualization, DeepLIFT,
  InfoGAN) proved fragile, since adversarial inputs can move activations arbitrarily without
  changing the prediction; some papers argued classical AI is more interpretable, while
  others extended interpretation to deep Q-networks or built it into network structure.
- AI for social good: fake news detection and filtering, image classification against human
  trafficking, feature engineering for citizen-science data, social robots that outperform
  non-social ones in early literacy teaching, and Bayesian and unsupervised approaches to
  fairness.
- Games and simulation workshop: as AI moves into complex real environments, training needs
  high-fidelity simulators, but the "reality gap" undermines them.
- The highlighted fix is domain randomization: a robot hand trained only in simulation
  transferred to the physical robot because perception and physics parameters (lighting,
  friction, actuation, contact models) were randomized during training, making the policy
  insensitive to them.
- The authors note they are considering the same idea for their business, where real
  markets differ from simulated ones.

## Relevance to us

- **Testing and simulation:** a strategy tuned against one fixed simulator configuration can
  overfit it; randomizing simulator parameters across runs tests robustness to the gap
  between our simulators and real venues. **Action:** add a
  `Market_sim.Config.randomize : seed:int -> t -> t` helper in
  [exchange-core](../../../repos/exchange-core.md) that draws `vol_bps`, the post, cancel
  and market probabilities and `max_offset_bps` from ranges, with an expect test showing the
  drawn configs are reproducible per seed and stay in range; running
  [market-maker](../../../repos/market-maker.md) end-to-end across several seeds is the
  follow-up.
- The interpretability and social-good themes do not apply to us.

Tags: `ml`, `simulation`, `testing`
