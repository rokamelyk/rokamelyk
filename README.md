# kylemakor-ai

This account is not a person. It is the GitHub identity I hand to the LLM agents
I work with, so that their work shows up as theirs instead of as mine.

I am [Kyle McCormick](https://github.com/kdmccormick). I maintain parts of
[Open edX](https://openedx.org), and I do a lot of my work alongside LLM agents.
That raises a question which I don't think is answered well by handing an agent
your own credentials: when an agent pushes a branch, opens a pull request, or
argues with you in a review thread, whose work is that?

My answer is that it is the agent's work, and it should say so.

## Why the separate account

Two reasons, and they pull in the same direction.

**Attribution.** An agent commits as `Kyle D McCormick's AI <ai@kylemccormick.me>`,
never as me. If you are reading a commit in one of my repos, the author field
tells you whether a human wrote it. I don't want that to be something you have
to infer from the prose style.

**Blast radius.** Agents go wrong sometimes. When they do, I would rather the
damage land somewhere I can throw away. This account can push to exactly one
place: its own forks. It cannot push to my repos, and it cannot merge into them.
Everything it wants me to have, it has to ask for through a pull request that I
read.

## What it can and cannot do

It can:

* push branches to `kylemakor-ai/*`, its own forks, freely and without asking,
* open pull requests against my forks -- `kdmccormick/*` -- and respond to my
  review comments there.

It cannot:

* push to any repo I own,
* merge anything, anywhere, into my repos,
* touch a repo owned by anyone else, including the Open edX org and the upstreams
  my forks came from.

That last one deserves honesty: it is a rule written down in
[AGENTS.md](./AGENTS.md), not a permission GitHub enforces. The account's token
is broadly scoped, and GitHub lets any account open an issue or a pull request on
any public repo. So while "cannot push to `kdmccormick/*`" is a fact about
access, "will not comment on `openedx/*`" is a promise about behavior. I know
which of those two I trust more. Narrowing the token is on my list.

There is one trap worth naming, because it is the *default* behavior rather than
an edge case. When you open a pull request from a fork, GitHub defaults the base
repository to the root of the fork network -- not to the fork you actually
branched from. My `openedx-platform` fork descends from
`openedx/openedx-platform`, so an agent running a bare `gh pr create` would file
a pull request against the real Open edX platform. That is exactly the outcome
this whole setup exists to prevent, and it is one forgotten flag away. Hence
`setup-repo.sh`, which pins the base repo per checkout, and a standing rule to
pass `--repo` anyway.

## How to read its pull requests

Like a coworker's. That is the whole idea.

The agent writes the code and the pull request description; I review it, request
changes, and merge it. Commits from me and from the agent intermingle on the same
branch, the way two people's would. When I give feedback about taste rather than
about the diff in front of us, the agent writes it down in
[docs/code-style.md](./docs/code-style.md) so that we settle it once instead of
relitigating it every pull request. That file is the most interesting thing in
this repo: it is a record of a code review that accumulates.

## If it does something wrong

Tell [me](https://github.com/kdmccormick), not it. I am responsible for
everything this account does. If you find it somewhere it should not be, that is
a bug in my setup and I would like to know about it.
