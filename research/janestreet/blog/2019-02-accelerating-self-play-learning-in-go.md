# Accelerating Self-Play Learning in Go

- Source: <https://blog.janestreet.com/accelerating-self-play-learning-in-go/>
- Published: 2019-02-28
- Kind: blog post

## Summary

- Announces the KataGo paper, code and trained nets: a personal research project by a Jane
  Street researcher, run on compute the firm provided.
- Context: AlphaZero, ELF OpenGo and Leela Zero needed thousands of TPUs/GPUs or a year of
  volunteer compute to reach top strength.
- The new techniques together appear to speed learning by roughly 5x versus Leela Zero to
  reach strong professional level, and close to 100x in early training.
- Reaching amateur-dan strength on 19x19 becomes feasible with a few GPUs in a day or two.
- One network can be trained to play across many board sizes at a small strength cost.
- Adding score maximization as a secondary training target speeds learning and lets the
  bot handle handicap games, which other zero-trained bots struggle with.
- Includes a board-ownership prediction head visualized per point.

## Relevance to us

- Weak relevance: reinforcement learning research for a board game. Nothing in
  [mm-core](../../../repos/mm-core.md) or the data platform uses learned models today.
- **Action:** none.

Tags: `ml`, `culture`
