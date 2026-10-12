# Accelerating Self-Play Learning in Go

- Source: <https://blog.janestreet.com/accelerating-self-play-learning-in-go/>
- Published: 2019-02-28
- Kind: blog post

## Summary

- Jane Street has been exploring machine learning for its models; this post announces the
  KataGo paper, source code, trained networks and an online bot from a researcher's
  personal Go project, run on compute the firm provided.
- Context: AlphaZero needed thousands of TPUs for days, ELF OpenGo about two thousand GPUs
  for over a week, and the volunteer-run Leela Zero more than a year to reach top strength.
- The runs here were much shorter (several short runs and one medium run) yet reached
  strong professional, possibly superhuman, strength.
- Combined techniques appear to speed learning roughly 5x versus Leela Zero to strong
  professional level, and close to 100x in early training.
- Reaching amateur-dan strength on 19x19 becomes possible with a few GPUs in a day or two.
- With the right architecture one network plays well across many board sizes, at a small
  strength cost.
- Score maximization as a secondary objective speeds learning and lets the bot play
  handicap games sensibly, which zero-trained bots usually handle poorly.
- The network also predicts final ownership of each board point; more experiments were
  planned for later posts.

## Relevance to us

- No relevant insight: reinforcement learning for a board game; nothing in
  [mm-core](../../../repos/mm-core.md) or the data platform uses learned models.
  **Action:** none.

Tags: `ml`, `culture`
