# Building a UI Framework

- Source: <https://signalsandthreads.com/building-a-ui-framework/>
- Published: 2021-10-06
- Kind: Signals and Threads episode 11

## Summary

- The guest, who came from compiler work, builds Bonsai, Jane Street's OCaml library for
  browser UIs compiled to JavaScript with Js_of_ocaml. A side project is programmatic CAD
  using function representations (implicit surfaces), where union, intersection and
  negation are max, min and negation, and converting to meshes is the hard part.
- Incr_dom, the predecessor, followed the Elm architecture (a pure view from the model, and
  an apply-action function from model and action to a new model) and added Incremental, a
  smart memoization library, so small input changes cause small recomputation.
- Every UI framework hides an incrementalization engine, because displays change a little
  at a time and must update quickly.
- The real value of the Elm pattern is modeling interactions as an explicit state machine
  (model, actions, transition), which makes debouncing and guarding against accidental
  double actions straightforward, unlike direct mutation in event handlers.
- Incr_dom also computed apply-action incrementally, which lets expensive derived structures
  (sorted and filtered views of tables with hundreds of thousands of rows) be shared with
  keyboard navigation. The cost was 50 to 70 lines of boilerplate to compose two components,
  so teams built monoliths.
- Bonsai began as one type bundling incremental view, extra outputs and apply-action. It
  then dropped the hard-coded view: a component computes any value, and more than half of
  the guest's components are state machines with no view at all.
- Components hide their model and action types; the main type is parameterized only by the
  value produced, so state is local to each component.
- Components form a directed acyclic graph, not a tree, so a value (for example a text
  box's contents) can flow to a sibling (a button's enabled state) without routing through
  a parent.
- The graph is static once the app starts (dynamic switching among known subgraphs is
  allowed). At startup Bonsai runs compiler-like passes: constant folding, merging cheap
  nodes, and choosing among incremental algorithms for map-like data per node; a debugger
  over the known graph is possible.
- A Bonsai app is three languages: OCaml building the graph, Bonsai's own constructs
  (`let`, `if`, `match`, recursion) made to look like OCaml via ppx, and OCaml business
  logic inside nodes. Purity is required but not enforced by the type system.
- Metaprogramming is described as essential in modern languages; OCaml's ppx system is
  powerful but heavyweight for small local macros, and macros are configured in the build
  rather than in the language.
- Adoption came from backwards compatibility with Incr_dom (incremental migration) and from
  actively promoting reusable components through a large examples collection.
- CSS name clashes between components are fixed by a ppx that hashes class names with file
  and content; the guest defends CSS itself and blames browser layout complexity instead.
- Inside Jane Street, web apps are long-lived single pages on fast networks connected by
  websocket, so bundle size, code splitting and server rendering hardly matter.
- Wishes for the web: direct access to layout and rendering engines instead of reinventing
  text boxes on canvas (the Houdini proposal); Svelte's compile-ahead components are
  admired.
- Excel and Blender's shader node editor are praised for showing intermediate values right
  next to the code that produced them, which makes them powerful debuggers.

## Relevance to us

- We have no UI, so most of this episode does not apply directly.
- **Logs and state machines:** Explicit model/action/transition machines make behavior
  inspectable; `Strategy` in [mm-core](../../../repos/mm-core.md) already has this shape
  (`on_book`, `on_fill`, `tick`). **Action:** add a debug option in
  [market-maker](../../../repos/market-maker.md) that logs each strategy input and the
  resulting plan as one sexp line, so a session can be replayed through `Strategy` in a
  test.
- **Research tooling:** Seeing intermediate values next to their inputs is what makes Excel
  and node editors effective. **Action:** add a DuckDB view in
  [market-data](../../../repos/market-data.md) that joins BBO and trades on time buckets so
  a quoted spread and the trades that hit it can be inspected side by side.

Tags: `ui`, `state-machines`, `ppx`
