# A tutorial for building web applications with Incr_dom

- Source: <https://blog.janestreet.com/a-tutorial-for-building-web-applications-with-incrdom/>
- Published: 2019-01-15
- Kind: blog post

## Summary

- Jane Street web UIs are built on Incr_dom, an in-house framework modeled partly on
  React's virtual DOM.
- Rendering views efficiently from a changing shared model is an incremental computation,
  so Incr_dom is built on the Incremental library.
- Until this post, documentation was limited to a few blog posts, one talk and API docs,
  leaving would-be users mostly on their own.
- The post announces example-driven tutorials in the incr_dom repository that tear down
  sample applications, covering both getting started and more advanced features.

## Relevance to us

- We have no web UI. If we build a dashboard over the recorder or the market maker,
  Incr_dom (or its successor Bonsai) is the in-ecosystem option; nothing to do now.
  **Action:** none.

Tags: `ui`, `ocaml-practice`
