# Applied board review consolidation — 2026-10-31

Board `horizon-research-2026-10` was read back after supported CLI mutations. This records the applied review/capacity trim, not completion of every milestone/integration amendment.

## Verified counts

| Non-archived card class | Before this trim | After |
|---|---:|---:|
| Implementation | 18 | 18 |
| Review, including completed historical assessments | 39 | 26 |
| Repair | 3 | 3 |
| Control / external gate | 2 | 2 |
| **Non-archived total** | **62** | **49** |
| Archived historical cards | 2 | 15 |
| Total stored records | 64 | 64 |

Thirteen pending duplicate quality reviews were archived, not completed/passed/deleted. Their requirements are consolidated into the existing specification card, now a combined independent review with separate SPEC and QUALITY verdicts. Eight completed cards remain visible as history. UI views that include archived cards still show 64 stored records; the normal non-archived view has 49.

## Exact mapping

| Package | Combined review retained | Unperformed duplicate archived |
|---|---|---|
| H02 | t_4c978e7e | t_da9a423e |
| H05 | t_0571f119 | t_490950bb |
| H06 | t_33cadb23 | t_7e170254 |
| H08 | t_a24089d1 | t_b3927c41 |
| H09 | t_e95e1d9a | t_08db3fbd |
| H10 | t_d09d495d | t_effa3479 |
| H11 | t_e4fb9290 | t_b9685cd9 |
| H12 | t_dd3f2384 | t_3e277440 |
| H13 | t_62b21302 | t_b458e6e8 |
| H14 | t_7ae965df | t_235dc176 |
| H15 | t_40620e92 | t_312f7abd |
| H16 | t_b8402be1 | t_30d1da3e |
| H17 | t_6c34a98b | t_4d3a60b9 |

H01 duplicate t_a977747f and automatic synthesis t_b884f54a were already archived before this trim. H00 completed evidence and completed H01 FAIL assessments remain preserved. H03/H04/H07/H18 now have combined review plus explicitly focused authorization/privacy, ownership/migration, deterministic-finance, and final-readiness specialist reviews respectively. These four extras are justified risk checks, not generic repeats.

## Dependencies and preservation

Successors of archived reviews now depend on the surviving combined review. The six capacity-only package edges H04→H05, H05→H06, H02→H11, H12→H13, H13→H14, H10→H16 were removed. Actual artifact prerequisites remain, including H02→H13, H03→H04, H05/H06→H07, H04/H07→H08, domain/UI inputs and the development-PC gate. Capacity is managed by scheduled holds and the existing two-worker cap.

Verified: dependency graph is acyclic; no archived card is a prerequisite of a non-archived card; all thirteen duplicate cards read back as archived; all thirteen survivors carry the combined-review amendment. No source file, profile/global configuration, live service or user data was changed by the trim. Running H01 repair was not interrupted; it independently reached its review-required handoff during these board changes.

Snapshots: `trim-before.json` and `trim-after.json` preserve exact card bodies and dependency edges. Original request/baseline evidence remains unchanged. Restoring old bodies/links is possible through supported CLI without deleting history.

## Remaining work — not falsely called finished

The broader amendment already describes H15A/H15B early integration and held follow-ups in planning documents. Their card materialization and full package-to-live-board synchronization are NOT established by this trim. The controller must finish that bounded synchronization before releasing affected integration units, including H16 phasing and full-release follow-up accountability. Do not use the old board materializer to restore archived generic reviews or capacity edges.

Next source gate is the H01 semantic repair t_65d844d6, delivered to controller for artifact verification, then independent combined reviewer t_2755dea8. Author completion is not acceptance. PC runtime/build acceptance and operator live release remain held.
