# Observed style

Kyle's taste as read out of his merged pull requests in the `openedx` org, rather
than as told to me directly. [code-style.md](./code-style.md) is the record of
what he has actually said in review; this is inference from artifacts. When the
two disagree, code-style.md wins and the entry here gets corrected or deleted.

Every entry cites the pull request it came from, so the original wording stays
findable. The PRs read so far are listed at the bottom — extend that list rather
than re-reading the same ones.

## Decisions get written down with the losing arguments intact

ADR 0013 gives "Arguments in favor of 'Studio'" and "Arguments in favor of
'CMS'" equal billing, seven bullets each. The decision it reaches is the second
one, and the Decision section names the single factor that actually settled it:
that changing "Studio" to "CMS" is far cheaper than the reverse. Not a summary of
the case for CMS — the one thing that tipped it.

The vote tally was public, including that he lost it 4-3:

> "Although that's 4-3 in favor of Studio, the pro-CMS votes seem to be more
> blocking, with @robrap recommending against going forward with Studio
> altogether unless I were to expand this into a full-blown renaming project,
> which I'm not going to do. Also, the success of this decision does hinge on
> @regisb's willingness to reflect it in Tutor, so I am giving his vote some
> extra weight."
> — [platform#29534](https://github.com/openedx/openedx-platform/pull/29534)

And when a reviewer named an alternative that everyone had rejected without
noticing, it went into the document rather than staying in the thread:

> "Good catch -- you are right that we're implicitly rejecting it. [...] Since
> increasing consistency is my primary goal here, I'm not entertaining that
> option. I'll update the ADR with this reasoning."
> — [platform#29534](https://github.com/openedx/openedx-platform/pull/29534)

So: an ADR carrying only the winning argument isn't finished. Make the case
against your own decision at full strength, say which one factor decided it, and
write down the options you rejected implicitly. The settings ADR keeps a whole
"Alternatives Considered" section for a structure it explicitly won't pursue,
along with the condition that would bring it back — "will keep it in mind as an
alternative if we encounter difficulties with the plan laid out in this ADR"
([platform#36224](https://github.com/openedx/openedx-platform/pull/36224)).

## Consistency beats the better name

> "As much as I personally would love to rename it `backend-app-authoring`, I am
> avoiding this suggestion because [I think it would pull us away from
> consistency](https://xkcd.com/927/) even if everyone liked the new name, which
> isn't guaranteed."
> — [platform#29534](https://github.com/openedx/openedx-platform/pull/29534)

The question when naming isn't which name is best, it's which name the codebase
can converge on. "I would love to call it X" is an argument against X if the
codebase is already 50% Y.

Note the bar he set for success, in the same thread: 50/50 today, 75/25 after the
ADR, and he'd be happy. Not 100%. A convention wins when the leftovers read as
obviously old, not when they're gone.

## A name has to say which of the things it does

> "I think this is at least partially due to the fact that `refresh_children` is
> an ambiguous name. [...] Just based on the name, it's not clear whether it (a)
> updates to the latest library, (b) pulls blocks in from the library, or (c)
> just re-selects blocks for a single learner. In reality, the function can do
> either (a+b) or (b) depending on its args."
> — [platform#33263](https://github.com/openedx/openedx-platform/pull/33263)

The fix was `sync_from_library` with an `upgrade_to_latest` flag: the name states
the always-part, the flag names the sometimes-part. He took the rebase pain for
his coauthor to land it mid-PR.

The same instinct catches a name that's merely wrong:

> "'deduplicate' means when you have multiple instances of the same thing, so you
> merge them all into one instance. This is kinda the opposite: we have multiple
> things (containers) and we want to find a key for each one so that they all
> remain separate."
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873)

And the backend keeps its own vocabulary even when the UI has settled on another
word — the REST API is `migrations`, "even though the UI will say 'Import'"
([platform#36873](https://github.com/openedx/openedx-platform/pull/36873)).

## Cut the scope, link the remainder

Known-imperfect things ship, but never silently. Each one leaves a link behind:

* Dead code doesn't get parked in the tree. "My preference is to never add dead
  code, so let's just keep one implementation (the incremental one). But in order
  to keep the bulk-create code available in case we want to reinstate it later,
  can you just paste this function as a code-block in a comment on [the issue]?"
* A `TODO` that survives review needs an issue attached: "If we're going to leave
  this in the PR, then please create follow-up issue and link it here to help
  prevent us from forgetting about it and leaving dead code here."
* A bug found during final review doesn't have to block the merge: "Ah, you're
  right, that is a bug, and we should fix it before Ulmo. But I agree that we can
  still merge this PR now. Can you open a followup ticket for this?"
* Odd behavior confirmed to predate the branch gets logged, not fixed here: "it
  seems wrong that DRCB's version of A doesn't have overridden content, but
  that's an artifact of how LC components handle duplication, and I confirmed on
  stage, so :shrug: I added it to my running list of follow-ups"
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873),
> [platform#33263](https://github.com/openedx/openedx-platform/pull/33263)

The settings ADR does this at plan scale: a step list where each step is marked
breaking or non-breaking, with the genuinely undecided part deferred to a linked
issue rather than guessed at
([platform#36224](https://github.com/openedx/openedx-platform/pull/36224)).

## Strictness in proportion to what it would cost to move

> "Seems OK to me if we don't have a stricter enforcement mechanism. If
> MigrationContext were meant to be used across different edx-platform apps, then
> it'd be important to be more strict. But since it just is used for `tasks.py`,
> I think what you have now is fine."
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873)

Same PR, the flip side: a class used only within one module gets renamed
`_MigrationContext`, "as it's not meant to be used outside tasks.py."

The architectural version of the same idea sets the layout of a whole package:

> "The goal is to have manageable number of well-separated django apps at the top
> level, internally organized into applets. The top-level apps are hard to
> refactor (due to migrations) but the internal applets are very easy to
> refactor."
> — [openedx-core#478](https://github.com/openedx/openedx-core/pull/478)

Boundaries that would be expensive to move later get few, deliberate, and
machine-enforced (that PR wires up `importlinter`). Boundaries that are cheap to
move stay loose. Effort spent policing a cheap boundary is wasted twice: once
writing it, once fighting it.

## Don't parse a format you don't own

> "I'm unsure if we should be doing direct string manipulation of these keys. As
> you're familiar with, when we work with OpaqueKeys (like CourseKeys) it's best
> practice to use the objects methods (`course_key.run`, etc.) instead of
> assuming the key format."
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873)

He researched it and came back with a resolution that costs a query per block:

> "It adds up to one query for each existing block, but I think this is worth the
> robustness, and if we see performance issues we can address it in the future."

Robustness first, optimize on evidence. Relatedly, a parameter derivable from
another parameter is a chance to disagree with yourself: he twice endorsed
replacing an `is_v2_lib: bool` argument with
`isinstance(library_key, LibraryLocatorV2)`
([platform#33263](https://github.com/openedx/openedx-platform/pull/33263)) — the
same one-source-of-truth reflex as the [code-style.md](./code-style.md) entry on
configuration defaults.

## A docstring that lies is a defect, fixed in the same PR

Across #33263 and #36873 the single most common review comment is that a
docstring or test name no longer describes the thing under it. "Docstring is
wrong. Here's a more accurate one." "This test is no longer testing what it says
in the docstring." "which was just not an accurate description of what it tests."
"It's not above any more; let's make the docstring agnostic of where in the file
the function is."

Two things follow. Renaming a test is part of fixing it — several tests in #33263
got renamed, merged, or strengthened while their behavior was being repaired,
each with a note on the line saying what changed and why. And a docstring
shouldn't encode where the code sits, because that's the fact most likely to go
stale first.

The trigger for writing a comment at all is a wrong inference a reader would
predictably make, not a general urge to explain. From the migrator's models: a
nullable field gets a paragraph because NULL there means something non-obvious
("this just means that none of them were authoritative"), and a mutable field
inside an otherwise-frozen dataclass gets flagged because "a dev might assume
that this field is kept constant as well"
([platform#36873](https://github.com/openedx/openedx-platform/pull/36873)).

## Manual testing is a script, not a claim

Bug reports and test reports both come as numbered steps someone else can run,
with expected and actual split out and a reference for what "correct" means:

> "Expected behavior (confirmed on master): the child's overriden title is also
> overriden in the duplicate lib content block. Actual behavior (confirmed on
> this branch): the child has the original title from the source library."
> — [platform#33263](https://github.com/openedx/openedx-platform/pull/33263)

Where the correct behavior wasn't obvious, he went and found an authority for it
— a specific unit on edX Stage — and wrote the comparison against that rather
than against his own expectation. PR descriptions carry the same thing as a
walkthrough with screenshots
([platform#36873](https://github.com/openedx/openedx-platform/pull/36873)).

This is what the **Testing** section in [../AGENTS.md](../AGENTS.md) is asking
for: steps, expectation, result.

## Ask before you assert, and say what you don't know

Reviewing code he didn't write, the default move is a question, not an
instruction: "Why do we need to catch IntegrityError?" — which got the honest
answer that the function wasn't needed at all. When he doesn't know, he says so
in the thread and comes back: "These entity keys are new to the platform and I'm
not sure if we have an established best practice yet... let me do some research
and come back to this comment."

The same applies to code he's about to change. Finding an unexplained bit of
duplication logic, he dug up the ticket and the 2015 PR that introduced it before
touching it, and reported the result without overclaiming: "I'm not going to say
I fully understand it, but at least there's clearly a reason."
([platform#33263](https://github.com/openedx/openedx-platform/pull/33263),
[platform#36873](https://github.com/openedx/openedx-platform/pull/36873))

Find out why the fence is there. Say plainly how sure you are once you have.

## Sample studied so far

Round 1, 2026-07-30 — merged PRs authored by `kdmccormick` in `openedx/*`:

* [platform#29534](https://github.com/openedx/openedx-platform/pull/29534) —
  ADR: CMS vs Studio terminology, plus `STUDIO_CFG` → `CMS_CFG` (2021, 24
  comments)
* [platform#33263](https://github.com/openedx/openedx-platform/pull/33263) —
  V2 libraries in LibraryContentBlock (2023, +1596/-572, 72 comments)
* [platform#36224](https://github.com/openedx/openedx-platform/pull/36224) —
  Settings Simplification ADR (2025, +362, prose only)
* [platform#36873](https://github.com/openedx/openedx-platform/pull/36873) —
  `modulestore_migrator` (2025, +3324, 55 comments)
* [openedx-core#478](https://github.com/openedx/openedx-core/pull/478) —
  flat top-level APIs (2026, 288 files)
