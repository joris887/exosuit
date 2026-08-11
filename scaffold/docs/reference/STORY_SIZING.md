# Story Sizing

Project-level sizing policy. Loaded by `/ideate`, `/story-cycle`, `/discover`, and `/backlog-review`.

**The canonical size table lives in `.claude/skills/ideate/references/story-template.md`.**
This file exists for project-specific *deviations* — it deliberately does not restate the table,
so the two cannot drift apart.

## Framework Default

Size follows **conceptual cohesion, not file count**.

> If I split this story, do I get two independently meaningful pieces — or artificial seams and a
> broken intermediate state?

- Two meaningful pieces → split.
- Artificial seams → keep it whole, however many files it touches.

Sizes: `TRIVIAL` · `SMALL` · `STANDARD` · `LARGE` · `XL`.
A story spanning genuinely unrelated topics is not a size — it is a bundle, and splits by topic.

**Large is permitted, never mandated.** Do not create XL stories because they are allowed.

## Self-Contained by Default

Beyond size, shape stories to stand alone where it makes sense: one complete outcome
per story (outcome over output), genuine prerequisites only in the Dependencies field,
shared groundwork extracted into setup stories. Independent stories can be built in
parallel (`/parallel-work`); dependent or file-overlapping stories belong in one
branch, worked sequentially. Independence never outranks cohesion — an artificial
split is worse than an honest dependency.

## Project Deviations

<!-- /bootstrap: leave this section empty unless the user states a specific sizing policy.
     An empty section means "we follow the framework default", which is the right answer
     for most projects. Only record genuine deviations here. -->

_None — this project follows the framework default._

<!-- Example of a real deviation:
### Cap stories at STANDARD
This project runs on a small context budget and ships behind a weekly release train, so LARGE and
XL stories are not used. Anything that would be LARGE is split along the SPIDR axes even where the
seams are slightly artificial.
**Why:** [reason]
-->

## When To Record a Deviation

Only when the project genuinely needs to differ. Good reasons:

- A regulated context requiring every story to be independently auditable
- A release process that cannot ship partial mechanisms
- A team convention that predates the framework and works well

Not good reasons:

- "XL stories feel too big" — that is the cohesion test's job, not a policy
- Restating the framework default in different words
