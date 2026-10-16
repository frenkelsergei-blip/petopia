# Adventure bag and reusable crate prototype

The user requested an adventure bag and reusable boxes/accessories after showing a high ledge that could not be reached directly. This is the first tool in that system. See design amendments A05–A06; this extends the GDD rather than pretending all of it was already specified.

## Play

In **Windmill Walk**, find the visible crate bundle on the lower path around the flower hill. **E** picks up three reusable wooden crates. **B** or **Bag** opens inventory and pauses the adventure. Build 1 / Build 2 places a crate at the corresponding nearby numbered spot. E is a quick placement action for the closest spot.

The current high-ledge puzzle uses one crate at spot 1 and a two-crate stack at spot 2. Stand beside the build area, place the steps, jump to the single crate, then the stack, then the high ledge. A crate is 24 world pixels high and wide. This sequence is tested with the existing player controller; it does not grant an untested higher jump.

**Pack all placed crates** returns them to the bag from anywhere, without cost or destruction. They can then be used at the marked spots in The Lost Picnic or in Windmill Walk. Ownership and all level placements survive saving/reopening. Picking up the original bundle again cannot duplicate ownership.

Three owned crates, at most two per spot, and authored building spots are provisional prototype limits. Free-form construction, crafting, additional accessories, backpacks with capacity upgrades and a wider item catalogue are not implemented. The lower main route remains usable without these optional tools.

## Safety and persistence

Placement checks ownership, spot range, stack limit and overlap with the child. Invalid placement reports a reason without consuming anything. A crate cannot be placed inside the child. Packing prevents a lost-tool dead end and frees tools that were placed in another level. Save validation rejects impossible counts, unknown spots and placements exceeding ownership.

Crate pickup and layouts are complete coalesced progress snapshots using the ordered background writer; normal save/quit flushes them. Purchases and completion rewards remain durable transactions. A forced termination may lose very recent unflushed progress, as described in `performance.md`.

The trail-tool suite uses the real visible pickup, bag buttons and physical colliders. It proves that a direct jump cannot reach the chosen ledge and that three ordinary crate-step jumps can, then verifies packing, cross-level reuse, reload, invalid placement and renderer/collider consistency. A complete audit of every optional upper-route jump remains open.
