# Observed style

What Kyle's code and writing feel like, read out of his merged pull requests in the
`openedx` org. [code-style.md](./code-style.md) is the rules file, things he has
actually told me. This file is impressions, off a sample of fifteen PRs.

So read it for calibration, not compliance. Where something shows up all over the
sample, it's probably how he works. Where it's one instance, the entry says so.
Where this contradicts code-style.md, code-style.md wins.

> "you've written this down as if it's black and white edicts. e.g., `Decisions
> get written down with the losing arguments intact` because you saw I did that
> once. try to go more for vibes, and less for hard-and-fast rules."
> — Kyle on [rokamelyk#5](https://github.com/rokamelyk/rokamelyk/pull/5), which is
> why this is a rewrite.

The PRs are listed at the bottom. Extend that list rather than re-reading them.

## Names get longer

The clearest single signal in the sample. An entire 42-file PR
([platform#35523](https://github.com/openedx/openedx-platform/pull/35523)) exists
to turn `DescriptorSystem` into `ModuleStoreRuntime`, `CachingDescriptorSystem`
into `SplitModuleStoreRuntime` and `OldModuleStoreRuntime`, `ImportSystem` into
`XMLImportingModuleStoreRuntime`. Thirty characters, shipped. Inside the classes,
`self._cds` became `self._runtime`. Nothing in that diff got shorter.

Test-only helpers got the same treatment — `DummySystem` →
`DummyModuleStoreRuntime`, `InMemorySystem` → `InMemoryModuleStoreRuntime` — even
though nobody outside those files reads them.

What seems to drive it is ambiguity rather than length. The trigger in
[platform#33263](https://github.com/openedx/openedx-platform/pull/33263) was that
`refresh_children` could mean three different things depending on its arguments;
it became `sync_from_library` with an `upgrade_to_latest` flag, and he ate the
rebase cost for his coauthor mid-PR to do it. `get_library_version` became
`get_latest_library_version` — "Same functionality, just a more specific name."

Not a rule about short names, though: locals stay casual (`mss =
ModuleStoreSerializer.create(...)`), and `_ = lambda text: text` sits at the top
of `item_bank_block.py` without apology.

## Underscores mark blast radius

`_ConfigurableFragmentWrapper`, `_MetricsMixin`, `_ModuleSystemShim`,
`_MigrationContext`, `_YAML_TOKENS`. When something stops being part of the
surface, it gets the prefix in the same PR that shrinks its reach.

The reasoning shows up explicitly in review, and it cuts both ways — the same
comment that asks for more strictness also declines to ask for it:

> "If MigrationContext were meant to be used across different edx-platform apps,
> then it'd be important to be more strict. But since it just is used for
> `tasks.py`, I think what you have now is fine."
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873)

The architectural version, from
[openedx-core#478](https://github.com/openedx/openedx-core/pull/478): top-level
Django apps are "hard to refactor (due to migrations)" so there are few of them
and `importlinter` enforces the boundaries; the applets inside them are "very easy
to refactor" and stay loose.

`_YAML_TOKENS` even carries its own discouragement — "Please avoid adding new
references to `_YAML_TOKENS`. Such references make our settings logic more
complex."

## Comments show up where you'd guess wrong

Not "few comments" and not "short comments" — the sample has both long and short.
What they have in common is that they sit exactly where a reasonable reader would
form a wrong belief:

* Dropping `None` overrides but not `False` ones, in a dict merge, gets a
  two-line comment because `False` is the trap
  ([platform#29156](https://github.com/openedx/openedx-platform/pull/29156)).
* A `vars().update()` gets a note that mutable values stay aliased, "This is
  intentional, in order to maintain backwards compatibility with old Django
  plugins."
* A nullable FK gets a paragraph because NULL means something non-obvious:
  "Note that `forwarded` can be NULL even when 1+ migrations have happened for
  this source. This just means that none of them were authoritative."
* A mutable field inside an otherwise-frozen dataclass gets flagged on review
  because "a dev might assume that this field is kept constant as well."

They're addressed to the next person, in the conditional, which is the
code-style.md entry on hazards showing up in his own hand:

> "Future devs: If you ever refactor this view to remove the user filter, be sure
> to enforce permissions some other way."
> — [platform#37711](https://github.com/openedx/openedx-platform/pull/37711)

Length follows from the surprise, not from a budget. The longest comment in the
sample is ten lines, in #37711, and it's there because the data model doesn't
enforce an invariant the code relies on — so it states the invariant, admits it
isn't guaranteed, and justifies each fallback separately.

He'll also just say when something is bad and shipping anyway, in-line and
briefly: "(Hard-coding these exact 3 container types here is not a good pattern,
but it's what is needed here in order to avoid additional SELECTs while
determining the container type)." And when he doesn't know: "TODO: This logic is
somewhat insane. We're not sure if it's intentional or not. We've left it as-is
for strict backwards compatibility, but it's worth revisiting."

## One place for a default, pursued to an unreasonable degree

code-style.md already has this as a stated rule. Worth seeing the scale he'll
apply it at:
[platform#36131](https://github.com/openedx/openedx-platform/pull/36131) deletes
702 lines whose entire content was `SETTING = ENV_TOKENS.get('SETTING',
default)` — the second default for each value — and leaves a banner behind:

```
# DO NOT ADD NEW DEFAULTS HERE! Put any new setting defaults in common.py
# instead, along with a setting annotation.
```

In the same diff, `FEATURES.get('ENABLE_CORS_HEADERS')` becomes
`FEATURES['ENABLE_CORS_HEADERS']` — if a key is guaranteed present, indexing says
so and `.get()` lies. That's the `os.environ[...]` example from code-style.md,
four years earlier and in production settings.

The constructive half, from
[platform#29156](https://github.com/openedx/openedx-platform/pull/29156): a
function that took a `credentials` dict became one that takes
`connection_overrides=None` and does `{**settings.COURSEGRAPH_CONNECTION,
**provided_overrides}`. Defaults in settings, overrides layered, nothing
duplicated. New settings in that PR arrive with type annotations
(`COURSEGRAPH_CONNECTION: dict = {...}`) and full `.. setting_name:` /
`.. toggle_name:` annotation blocks.

## Tests that read like sentences

Distinctive enough to call out, though it's really one PR
([platform#29156](https://github.com/openedx/openedx-platform/pull/29156)) doing
it thoroughly. Patchers get hoisted to module-level constants with prose names,
so the decorator stack is legible:

```python
_pretend_last_course_dump_was_may_2020 = mock.patch.object(
    tasks, 'get_command_last_run', new=(lambda _key, _graph: "2020-05-01"),
)
_make_neo4j_graph_raise = mock.patch.object(
    tasks, 'Graph', side_effect=py2neo.ConnectionUnavailable('we failed to connect or something!')
)
```

Fixtures are named for what makes them different (`course_updated_in_april`,
`course_updated_in_june`), assertions come in blocks under comment headers ("# No
errors should've been logged."), and the test bodies say what each assertion
demonstrates rather than what it checks.

The nicest trick in the sample, from
[platform#24718](https://github.com/openedx/openedx-platform/pull/24718): the
bucketing hash is faked with `lambda group_name: len(group_name)`, so every
expected value in the test is computable in your head, and `assert
flag.get_bucket(course_key_2) == 11` becomes readable instead of magic.

Test names and docstrings get repaired as part of fixing a test, not separately —
several in #33263 were renamed, merged, or strengthened, each with a review
comment saying what changed and why. "This test is no longer testing what it says
in the docstring" is the most common review note he leaves.

## Fewer doors, more optional arguments

A recurring shape, several instances:

* `is_enabled_without_course_context()` deleted; `is_enabled(course_key=None)`
  covers both ([platform#24718](https://github.com/openedx/openedx-platform/pull/24718)).
* `refresh_children` split into one function with a flag rather than two
  functions ([platform#33263](https://github.com/openedx/openedx-platform/pull/33263)).
* `MakoDescriptorSystem` dissolved into `ModuleStoreRuntime` with an optional
  `render_template=None`, removing a layer from the MRO
  ([platform#35523](https://github.com/openedx/openedx-platform/pull/35523)).
* Seven `XBlock` mixins collapsed into `core.py`
  ([XBlock#718](https://github.com/openedx/XBlock/pull/718)).

It isn't merging for its own sake, though — the migrator app splits value objects
(`data.py`, frozen dataclasses and enums) from Django models (`models.py`) when
the split carries meaning. The pattern is closer to: a class that exists only to
be mixed into one other class is a layer, not a boundary.

## Types where they pay, hedges where they don't

Newer code (2024+) leans on `from __future__ import annotations`, frozen
dataclasses, `t.TypeAlias`, `list[tuple[str, str]]`, `UserType | None`. Older
code uses `Arguments:` / `Returns:` docstring sections. Both are thorough; neither
is retrofitted onto the other era.

Once types are there he trusts them, and deletes the defensive branch:

> "Since we're using type annotations, mypy should forbid this from ever
> happening, so I think we can remove this case. Unless you were seeing it happen
> in your testing?"
> — [platform#36873](https://github.com/openedx/openedx-platform/pull/36873)

And where the value genuinely is approximate, the name says so rather than the
comment apologizing for it — `approx_last_published`, under a docstring that
opens "Approximately when was a course last published?"

## Opaque things stay opaque

[openedx-core#546](https://github.com/openedx/openedx-core/pull/546) renames `key`
to `ref` across 28 files, and the point of the rename is that you can't parse it.
The parser that used to raise now declines:

```python
def unpack_package_ref(package_ref: str) -> tuple[str | None, str | None]:
    """
    By convention, package_refs take the form ``"{prefix}:{org_code}:{package_code}"``,
    but this is only a convention — package_ref is opaque and the parse may fail.
    Returns ``(None, None)`` if the ref does not match the expected format.
    """
```

Same instinct in review, on someone else's string manipulation: prefer the
object's accessor over the format you inferred, and pay for it if you have to —
"It adds up to one query for each existing block, but I think this is worth the
robustness, and if we see performance issues we can address it in the future."

Where the old name has to survive in a serialized format, the code carries the
mismatch explicitly rather than renaming the wire format: `key =
serializers.CharField(source="package_ref")` with "the archive format still uses
`key`. A future v2 format may align the name."

## How he argues, in ADRs

Two ADRs in the sample, so this is how those two went rather than a law.

[platform#29534](https://github.com/openedx/openedx-platform/pull/29534) gives
"Arguments in favor of Studio" and "Arguments in favor of CMS" seven bullets each
and then picks the second one. The vote tally is public, and he lost it:

> "Although that's 4-3 in favor of Studio, the pro-CMS votes seem to be more
> blocking [...] Also, the success of this decision does hinge on @regisb's
> willingness to reflect it in Tutor, so I am giving his vote some extra weight."

The decision names one deciding factor rather than restating the case. An
alternative nobody had explicitly rejected got added to the document when a
reviewer noticed it was being rejected implicitly. And the bar for success was
stated as 75/25, not 100% — "it'll be much more obvious that the leftover 25% is
the 'old name'".

The thing he wouldn't do, even though he wanted to, was propose a better third
name:

> "As much as I personally would love to rename it `backend-app-authoring`, I am
> avoiding this suggestion because [I think it would pull us away from
> consistency](https://xkcd.com/927/) even if everyone liked the new name."

[platform#36224](https://github.com/openedx/openedx-platform/pull/36224) keeps an
"Alternatives Considered" section for a structure it won't pursue, with the
condition that would bring it back, and marks each step of its plan breaking or
non-breaking.

## How he reviews

Questions before instructions, when it's someone else's code: "Why do we need to
catch IntegrityError?" got the answer that the function wasn't needed at all. When
he doesn't know, he says so in the thread and comes back — "These entity keys are
new to the platform and I'm not sure if we have an established best practice
yet... let me do some research and come back to this comment."

Things that never seem to get waved through: dead code in the tree (it goes in an
issue comment instead — "My preference is to never add dead code"), a `TODO`
without a linked issue, a docstring that no longer matches. Things that do get
waved through: a real bug found at final review, with a follow-up ticket, rather
than holding the merge.

Before deleting something strange he goes looking for why it's there. In #33263
that meant tracking an odd duplication path back to a 2015 PR and a ticket, and
reporting the result without overclaiming: "I'm not going to say I fully
understand it, but at least there's clearly a reason."

## Where he isn't consistent

Worth knowing, so I don't over-fit:

* Line length runs to ~120 in code but comments and docstrings usually wrap
  closer to 100.
* `# pylint: disable=...` stays; `# lint-amnesty, pylint: disable=...` gets
  stripped whenever he touches the line, usually along with writing the missing
  docstring that earned it.
* `.format()`, f-strings, and `%`-style logging args all coexist; he matches the
  file rather than modernizing it in passing.
* `@@TODO` (double-at) appears as a personal work-in-progress marker in draft PRs
  and is expected to be gone before merge.

The through-line is that he doesn't fight the file he's in. Sweeping style
changes happen as their own PR, with their own justification, not folded into
feature work.

## Sample studied so far

**Round 1** (2026-07-30) — mixed code and prose, read closely:

* [platform#29534](https://github.com/openedx/openedx-platform/pull/29534) — ADR:
  CMS vs Studio, plus `STUDIO_CFG` → `CMS_CFG` (2021, 24 comments)
* [platform#33263](https://github.com/openedx/openedx-platform/pull/33263) — V2
  libraries in LibraryContentBlock (2023, +1596/-572, 72 comments)
* [platform#36224](https://github.com/openedx/openedx-platform/pull/36224) —
  Settings Simplification ADR (2025, prose only)
* [platform#36873](https://github.com/openedx/openedx-platform/pull/36873) —
  `modulestore_migrator` (2025, +3324, 55 comments)
* [openedx-core#478](https://github.com/openedx/openedx-core/pull/478) — flat
  top-level APIs (2026, 288 files)

**Round 2** (2026-07-30) — code-heavy, for Python style. Read closely:

* [platform#24718](https://github.com/openedx/openedx-platform/pull/24718) —
  course-unaware `ExperimentWaffleFlag` (2020, +192/-54)
* [platform#29156](https://github.com/openedx/openedx-platform/pull/29156) —
  CourseGraph refactor, admin actions, settings (2021, +763/-257)
* [platform#35523](https://github.com/openedx/openedx-platform/pull/35523) —
  ModuleStore runtime renames and mixin collapse (2024, 42 files)
* [platform#35553](https://github.com/openedx/openedx-platform/pull/35553) —
  `ItemBankBlock`, a new 540-line XBlock (2024)
* [platform#36131](https://github.com/openedx/openedx-platform/pull/36131) —
  `lms/envs/production.py` cleanup (2025, +253/-702)
* [openedx-core#546](https://github.com/openedx/openedx-core/pull/546) — `key` →
  opaque `ref` (2026, 28 files)
* [XBlock#690](https://github.com/openedx/XBlock/pull/690) — `usage_key` /
  `context_key` properties (2023, small)

Skimmed only — diffs sampled, comments read, not studied line by line:

* [XBlock#718](https://github.com/openedx/XBlock/pull/718) — collapse XBlock
  mixins (2024, +929/-988)
* [platform#34925](https://github.com/openedx/openedx-platform/pull/34925) —
  upstream sync with content library blocks (2024, +1562)
* [platform#37711](https://github.com/openedx/openedx-platform/pull/37711) —
  migrator edge cases and data issues (2025, +2555/-1842)
