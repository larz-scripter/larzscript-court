# LarzCourt

Staked-jury dispute resolution, written entirely in Larzscript, the
money-native language — a Schelling-point mechanism, the same shape
real decentralized courts like Kleros use. Jurors put their **own**
money on the line to participate, not the disputing parties. That
stake is what makes honest voting incentive-compatible: side with the
eventual majority and get your stake back plus a share of what the
minority lost; side with the minority — or don't vote at all — and
your stake is redistributed away instead.

Part of the [Larzscript ecosystem growth plan](https://github.com/larz-scripter/larzscript/blob/main/GROWTH.md)'s
flagship-app track (alongside [`LarzBank`](https://github.com/larz-scripter/larzscript-bank),
[`LarzBounty`](https://github.com/larz-scripter/larzscript-bounty),
[`LarzCrowd`](https://github.com/larz-scripter/larzscript-crowd),
[`LarzInsure`](https://github.com/larz-scripter/larzscript-insure),
[`LarzGig`](https://github.com/larz-scripter/larzscript-gig),
[`LarzDAO`](https://github.com/larz-scripter/larzscript-dao),
[`LarzExchange`](https://github.com/larz-scripter/larzscript-exchange),
[`LarzVM`](https://github.com/larz-scripter/larzscript-vm),
and [`LarzVest`](https://github.com/larz-scripter/larzscript-vest)).

## Why this is a different shape of problem than its siblings

Every sibling project's `require` decides ONE transaction — allow a
withdrawal, release an escrow, block a payout. `resolve()` here is
different again: after a vote closes, it decides the **direction** of
N separate payments at once, each juror's own money either flowing
back to them (plus a bonus) or moving to someone else entirely, purely
by which side of the vote they landed on:

```larzscript
let bonus = majority_total_stake > 0.0
  ? round(slashed_pool * (jr["stake"] / majority_total_stake), 2)
  : 0.0
let payout = round(jr["stake"] + bonus, 2)
```

A juror who never votes gets no special exemption — they're folded
into the losing side and slashed exactly like an active wrong vote,
the same real non-participation penalty Kleros-style courts use to
keep jurors actually engaged. A tie has no majority to reward or
minority to punish, so it just refunds every stake in full.

Splitting a slashed pool proportionally across an arbitrary number of
winners, independently rounded, means the payouts realistically never
sum back to exactly the pooled total — the same rounding-drift risk
[`LarzGig`](https://github.com/larz-scripter/larzscript-gig)'s
two-way milestone split hit. LarzGig's fix was a hard `require` reject
on any mismatch, which fits a 2-way split but is too strict for an
N-way proportional one (it would fail almost every real case). Here
the leftover cents are instead deposited deterministically on whoever
in the majority staked the most, so nobody's money is ever left
stranded in the holding wallet:

```larzscript
let dust = round(c["holding_balance"] - distributed, 2)
if largest_juror != nil and dust != 0.0 { payouts[largest_juror] = round(payouts[largest_juror] + dust, 2) }
```

## Quickstart

```bash
larzscript bin/larzcourt.lz fund alice 100
larzscript bin/larzcourt.lz create-case "Refund dispute" "did the item ship?" --period=3600
larzscript bin/larzcourt.lz join <case_id> alice 20
larzscript bin/larzcourt.lz vote <case_id> alice plaintiff
larzscript bin/larzcourt.lz resolve <case_id>   # after the voting period ends
```

State (wallets, cases, votes) persists to `board.json` in the current
directory across runs — each command is a fresh process; see "How it's
built" below for how that's made to work with a native `wallet` value,
which isn't something JSON can hold. Override the state file with
`--board=path/to/file.json`.

## Real transcript (`sh examples/demo.sh`, copy-pasted, not invented)

```
--- fund three jurors (demo-only faucet) ---
alice balance is now $100
bob balance is now $100
carol balance is now $100

--- case 1: alice and bob vote plaintiff, carol votes defendant alone ---
case f6dc795e  "Refund dispute"  open for 5s
full id: f6dc795e-c01c-4085-8f4c-f9294e604464
alice joined as juror, staked $20
bob joined as juror, staked $30
carol joined as juror, staked $10
alice voted plaintiff
bob voted plaintiff
carol voted defendant
--- carol's whole $10 stake is redistributed to alice and bob, proportional to their own stakes ---
ruling: plaintiff
alice: $104
bob: $106
carol: $90

--- case 2: alice votes, bob never shows up to vote at all ---
case 59db434f  "Late delivery dispute"  open for 5s
full id: 59db434f-6093-49eb-b062-c70f09ba73ec
alice joined as juror, staked $10
bob joined as juror, staked $10
alice voted plaintiff
--- bob never votes - treated exactly like voting the losing side, not exempt for staying silent ---
ruling: plaintiff
alice: $114
bob: $96

--- case 3: alice and carol split evenly - no majority, no slashing ---
case 393cfd2b  "Ambiguous contract dispute"  open for 5s
full id: 393cfd2b-1eca-4197-9ac6-ea2dd2f2e13f
alice joined as juror, staked $15
carol joined as juror, staked $15
alice voted plaintiff
carol voted defendant
--- a tie just refunds everyone their own stake, dollar for dollar ---
ruling: tie - all stakes refunded
alice: $114
carol: $90
```

## Commands

| Command | What it does |
|---|---|
| `fund <name> <amount>` | Demo-only faucet. |
| `create-case <title> <description> --period=<secs>` | Opens a case for voting, closing in `<secs>` seconds. |
| `join <case_id> <juror> <stake>` | Stakes real money to become a juror. Staking IS registering — there's no separate sign-up step. |
| `vote <case_id> <juror> <plaintiff\|defendant>` | Casts a vote. Only jurors who've staked can vote, and only before the deadline. |
| `resolve <case_id>` | Settles the case after its deadline: pays majority jurors their stake plus a share of the minority's, refunds everyone on a tie. |
| `list` | Lists every case with its juror count, status, and ruling. |
| `show <case_id>` | Full detail on one case, including every juror's stake and vote. `<id>` may be the short 8-character prefix `create-case`/`list` print. |
| `balance <name>` | Shows a balance. |

## How it's built

- **`lib/moneyx.lz`** — the bridge between the native `wallet`/Money
  type and a plain float, for persisting balances to JSON. There is no
  `float(money)` builtin; stripping the leading `"$"` off `str(m)` is
  the real, working conversion.
- **`lib/court.lz`** — `join()` moves real money into a per-case shared
  holding wallet via `escrow.open()`, the same vocabulary as
  [`LarzCrowd`](https://github.com/larz-scripter/larzscript-crowd)'s
  pledges. `resolve()` tallies votes, then pays every majority juror
  via `escrow.release()` or refunds everyone via `escrow.refund()` on
  a tie — no `require` blocks the settlement itself; the incentive
  design is entirely in *how much* each juror receives, not *whether*.
- **`bin/larzcourt.lz`** — the CLI. Each invocation loads `board.json`,
  does one thing, saves it back. `_find_by_prefix()` rejects a
  too-short/empty id outright rather than risk matching the wrong
  case — the same class of bug found and fixed in every sibling
  project, applied here from the start.

## Limitations (read before treating this as more than a toy)

- **`fund` is a faucet, not a payment rail.** There's no real deposit
  flow behind it.
- **No collusion resistance.** A real Schelling-point court (Kleros
  included) layers in commit-reveal voting, juror selection by stake
  weight, and appeal rounds specifically to make it expensive for
  jurors to coordinate on a dishonest ruling. None of that is here —
  votes are plain and immediately visible to anyone reading `board.json`
  before the deadline, so a juror can simply copy whatever the current
  majority is doing.
- **No identity/authorization model.** Anyone running the CLI can
  join, vote, or resolve as anyone.
- **Floating-point, not arbitrary-precision.** Larzscript's only numeric
  type is a double, the same limitation every Larz Stack money package
  documents.
- **Single-process, no concurrent access.** Two `larzcourt` invocations
  racing against the same `board.json` can clobber each other — fine
  for a personal CLI tool, not for anything multi-user.
- **`board.json` is not encrypted or access-controlled.** Don't put real
  financial data in it.

## Tests

```bash
sh tests/run_tests.sh
```

Real CLI output, diffed against `tests/*.expected` — `uuid.v4()` ids
normalized first, same as every sibling project. Covers: a clean
majority slashing a lone dissenting juror, a juror who never votes at
all getting the same penalty as an active wrong vote, an even tie
refunding every stake in full, and the too-short-id-prefix guard
(plus voting without having joined, and resolving before the deadline).

## License

MIT
