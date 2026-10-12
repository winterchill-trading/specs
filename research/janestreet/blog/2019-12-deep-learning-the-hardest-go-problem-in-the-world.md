# Deep-Learning the Hardest Go Problem in the World

- Source: <https://blog.janestreet.com/deep-learning-the-hardest-go-problem-in-the-world/>
- Published: 2019-12-06
- Kind: blog post

## Summary

- Update on KataGo, a self-play Go bot: a second 19-day run on up to 28 V100 GPUs passed the
  earlier one-week run in about three days and reached the strength of ELF OpenGo, roughly a
  50x reduction in compute versus that AlphaZero replication.
- KataGo became popular with players because it also optimizes score, so it plays well in
  handicap games where pure win-rate bots collapse, and it estimates score and territory and
  supports other board sizes and rules.
- Target: problem 120 of Igo Hatsuyoron (1713), widely seen as the hardest composed Go
  problem, full of huge trades and races with zero margin; prior bots, including KataGo,
  failed on it because of known blind spots in large-scale fights and unusual shapes.
- Method: one more week of self-play on the same 28 GPUs, with about 70 percent of games
  starting from the problem (one sixth from the initial position, the rest from random
  positions in human and bot variations) and 30 percent ordinary games as regularization.
- Start positions were sampled with probability decaying exponentially in move number so all
  depths were roughly equally likely; komi was set to the bot's own fair value (plus 1-point
  noise) so exact score mattered; the training data window was halved to shorten the
  feedback loop; the bot was never told the human answers.
- Result: the bot rediscovered known human tactics, including the strange "guzumi" move only
  late in the week, found some refutations in side lines, and proposed new main-line moves
  that flip the believed result from Black by 3 to White by 1 or 2 points.
- Caveats: the run was informal, some evaluations are over- or under-confident, and some
  lines need tens of thousands of playouts; open questions include replicability, training
  only from the initial position, cheaper methods, and general fixes for the blind spots.

## Relevance to us

- Game-playing reinforcement learning research; nothing in our stack trains models.
  **Action:** none.

Tags: `ml`, `research-tooling`
