# Code style

Kyle's taste as a software engineer, accumulated from PR review so it compounds
instead of getting relitigated every PR.

Entries go in only when Kyle has actually said something, in review or in chat —
this is a record of real feedback, not a guess at what he'd probably want. Cite
the PR so the original wording stays findable. If two entries ever conflict, the
newer one wins and the older one gets deleted rather than left to rot.

This is general taste, applying to every repo. Rules that are specific to one
codebase live in that repo's own `AGENTS.md`; the workflow lives in
[../AGENTS.md](../AGENTS.md).

## One source of truth per configuration point

Define a default in exactly one place. A second default for the same value isn't
a safety net — it's unreachable code that can only drift out of agreement with
the real one.

The worked example, from `openedx-template-site`: shell environment variables get
their defaults in `env_vars`, so a settings module that loads them writes
`os.environ['MYSQL_HOST']`, never `os.environ.get('MYSQL_HOST', '127.0.0.1')`.
The variable is always present, so the fallback never runs — it just sits there
looking authoritative and going stale.

> "Add defaults in exactly *one* place. [...] The ENV_VAR is always present and
> spurious_default is never used and thus subject to drift. [...] Follow a similar
> philosophy for other configuration points, too."
> — Kyle, in `openedx-template-site`'s `AGENTS.md`

That last sentence is the general form, and it's why this entry is here rather
than only in that repo. The same reasoning applies to a default declared in both
a config file and the code reading it, to a constant duplicated across two
modules, and to a value documented in prose next to where it's defined.

Corollary: when you find two sources for one value, deleting the redundant one is
the fix. Don't add a comment explaining that they must be kept in sync.

## Comments: 80/20 the understanding

Optimize a comment for how fast a reader groks it, not for how completely it
pins down the truth. Give up a little precision to get there. If a detail is
re-derivable by reading the file next to it, cut it.

> "Try to be more concise. De-prioritize precision just a bit for readability."
> "Just chill it out a bit, focus on easy-to-grok. '80/20' the understanding, if you will."
> — [#1](https://github.com/kdmccormick/openedx-template-site/pull/1)

Before (10 lines, and the reader is now an expert on mysql image internals):

```
# MySQL. Three consumers read these names:
#  1. the official mysql image's entrypoint, which creates MYSQL_DATABASE and
#     MYSQL_USER/MYSQL_PASSWORD -- but only while the datadir is empty, so once
#     per volume, not per container (compose.yml passes this file as env_file);
#  2. provision.sh, which reconciles the same objects on every run, covering
#     changes made here after the volume was already initialised;
#  3. our Django settings overrides (shared_settings_overrides_dev.py), which
#     build DATABASES from them.
# MYSQL_ROOT_* is ours alone (provision.sh, sqlshell.sh); the image's own name
# for the password is MYSQL_ROOT_PASSWORD, which is why it's spelled that way.
```

After (6 lines, same working understanding):

```
# MySQL. Three consumers:
#  1. compose.yml passes these to the official mysql image's entrypoint, which
#     initializes the db and user when the data volume is empty.
#  2. provision.sh, which re-applies them on every run.
#  3. our dev settings overrides, which build DATABASES.
# MYSQL_ROOT_* is just for our own scripts (provision.sh, sqlshell.sh).
```

Failure modes this is correcting, both of them mine:

* **Narrating detail nobody asked about.** Explaining *why* `MYSQL_ROOT_PASSWORD`
  is spelled that way answers a question no reader was going to ask.
* **Hedging into precision.** "reconciles the same objects on every run, covering
  changes made here after the volume was already initialised" is more exactly
  true than "re-applies them on every run" and communicates less.

## The "why" goes in the commit message

Don't tell the story of a bugfix in a comment. The commit message already tells
it, and `git blame` leads any curious reader there. A comment's job is to nudge
the average reader in the right direction — a clause, not a paragraph.

> "consider that your git commit message already does a good job of explaining the
> bug that we fixed. so, rather than trying to tell the story of the bugfix here,
> try to just explain the thing that would nudge the average reader in the right
> direction. if they want to hear the full story, they'll git-blame and see your
> commit. [...] i don't like a codebase littered with `# We did X because it stops
> Y from breaking we do Z` except in cases where that's reaallly necessary (and if
> that's necessary all over the place, then the codebase is probably spaghetti)"
> — [#1](https://github.com/kdmccormick/openedx-template-site/pull/1)

This replaced an earlier carve-out of mine — "keep the sentence that stops someone
reintroducing a bug" — so don't re-propose it. Even for a trap that fails
silently, the nudge survives and the story doesn't:

```
# Note: the official mongo entrypoint only recognizes these MONGO_INITDB_* names.
# Renaming them would start mongo with no auth at all -- quietly, and dangerously.
```

not

```
# Don't rename these to something friendlier: compose can only interpolate
# `${...}` from the host environment, never from an env_file, so relaying them
# under different names via `environment:` silently yields empty strings and
# mongo comes up with no auth at all.
```

Both steer the reader away from the same trap. Only the first respects that they
have somewhere else to look.

**Corollary worth taking seriously**: if a codebase seems to *need*
because-comments everywhere, that's evidence about the design, not a licence to
write more of them.

## Hazards are conditional, not historical

Write what *would* happen to a reader who changes this, not what *did* happen to
whoever wrote it. "Renaming these would start mongo with no auth" — not "renaming
these yields empty strings and mongo comes up with no auth," which quietly casts
the reader as a witness to a bug they never saw.

> "note how we are condition tense 'doing X *would cause* Y' rather than present
> tense 'doing X *causes* Y'. i need you to write with empathy for other
> developers: they are not you, so their lived experience is not that X _caused_ Y."
> — [#1](https://github.com/kdmccormick/openedx-template-site/pull/1)

This is the same instinct as the entry above, caught one level deeper. Present
tense is how the bug felt to the person who hit it. The next reader is not
debugging anything — they're considering an edit — so the useful framing is a
hypothetical consequence of *their* action:

* "would leave", "would break", "would put X in Y mode" — the hazard as they'd
  meet it
* not "yields", "comes up with", "silently disables" — the hazard as I met it

Applies beyond bug hazards: any comment stating a constraint reads better as what
breaking it would cost than as a war story. "A mismatch would break Studio login"
does more than a paragraph on how the mismatch was discovered.
