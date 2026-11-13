# cpurr 🐈

A cat that runs in your [Omarchy](https://omarchy.org) bar based on **CPU
usage** — the busier your machine, the faster it runs. After a few quiet cycles
it curls up and sleeps.

Omarchy port of the [Noctalia widget](https://github.com/Deoxizn/cpurr).
Pose art and animation timing are ported from
[CarloCattano/waycat](https://github.com/CarloCattano/waycat) by Carlo Cattano
(a Waybar custom module).

## Install

```sh
omarchy plugin add https://github.com/Deoxizn/omarchy-cpurr.git --enable
~/.config/omarchy/plugins/pizza.dirty.cpurr/setup/install.sh
```

The setup script downloads the Waycat pose font from the waycat repository
(it is not shipped in this repo). Then restart the shell so the bar picks up
the widget, and add cpurr to the bar.

## Settings

| Key    | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `size` | int  | `32`    | Pose art size in px. The bar clips widgets to its thickness, so keep it under that. |

The size lives in the widget's `shell.json` layout entry and is edited in the
bar's settings card, the same as other bar widgets.

## How it works

- `cpu_monitor.py` samples `/proc/stat` every 200 ms and prints the overall
  CPU usage percent; the widget reads those lines, no other subprocesses.
- Frame delay: `clamp(1000 / (4 + cpu%), 30, 250)` ms — a sprint under load, a
  stroll at idle (same numbers as waycat's `catloop.sh`).
- Below 2% usage for 4 frames in a row, it switches to the sleeping poses.
- Drawn as text with the Waycat font (frames A–E running, G–N sleeping),
  which is what makes the `size` setting possible. The widget slot is sized to
  the widest pose so the bar doesn't shift as the cat changes frames.

## Credits & license

Port of [Waycat](https://github.com/CarloCattano/waycat) by Carlo Cattano (pose font + `catloop.sh` timing) — MIT, see [LICENSE](LICENSE).
