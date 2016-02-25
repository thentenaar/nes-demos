![pentadecathlon](https://raw.github.com/thentenaar/nes-demos/master/src/neslife/neslife.gif)

### A simple implementation of Conway's Life for the NES

Originally, I had intended to develop this into a more game-like program,
but unfortunately I don't have enough spare time at the moment to devote
to finishing it up. Thus, this is largely still a work in progress.

However, the Life algorithm works pretty well. The general strategy
behind the algorithm itself is as follows:

Given a 30x20 board, break each row down into a group of 5 blocks,
containing 6 cells each. This way, each block can be represented in
one byte, with the most and least significant bytes reflecting the state
of the cells on the edge of the two horizontally adjacent blocks.

Then, use a rule-dependent lookup table to perform the neighbor counts,
and compute the next block state. All modified blocks are written to
a list in RAM, where the drawing code redraws any modified blocks.

Each block byte looks like this:

|  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
| --- | --- | --- | --- | --- | --- | --- | --- |
|  <  |  0  |  1  |  2  |  3  |  4  |  5  |  >  |

The bits for the adjacent cell state on the edges of thw row are taken
from the block at the opposite end of the row, if the board is configured
to have a toroidal topology (the default.) The board may also be
configured to be square.

Note that the algorithm itself should be usable on any 6502-based system,
not just the NES. See [life.asm](./life.asm) for the algorithm.

### Rules

The following Life rules are available:

- B3S23 (default)
- B1S12
- B34S34
- B36S23
- B38S238
- B38S23

Simply set the bank at $8000 to the bank specified by the corresponding
BANK define in [rules.inc](./rules.inc).

### Patterns

I've pre-programmed some life patterns in [patterns.asm](./patterns.asm)
which can be readily drawn on-screen. The one displayed by the program
is the [Pentadecathlon](http://www.conwaylife.com/wiki/Pentadecathlon).

### Notes

I've tested at least the [top 5 most common oscillators](http://www.conwaylife.com/wiki/List_of_common_oscillators) and some simple stills.

I haven't yet tested the edge cases, but I figured I'd release this
as-is for now with the aim of polishing it up a bit later on. This
has not been extensively tested on actual hardware.

Pull requests are welcome, if anyone finds it interesting to develop
this further in the meantime.
