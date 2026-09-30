# SIOC 221A — Analysis of Physical Oceanographic Data (Fall 2026)

Course material for SIOC 221A at Scripps Institution of Oceanography: lecture
notebooks, the data we use in class, and the shared routines the notebooks call.

The lecture notebooks themselves come through Canvas. **Every lecture is provided in
both a MATLAB and a Python version** — the text, the figures and the results are the
same; only the code differs. Use whichever language you prefer, and read the other one
alongside it, which is a fast way to pick up a second language. Whichever you use, the
notebooks expect the data and routines in *this* repository.

---

## Quick start

```bash
git clone https://github.com/malford11/SIO221a_Github_code_2026.git ~/SIO221a_Github_code_2026
```

Clone it to exactly that location and the setup cell at the top of every notebook
will find the data with no editing at all. If you put it somewhere else, set an
environment variable instead:

```bash
export SIO221A_ROOT="/wherever/you/put/SIO221a_Github_code_2026"
```

### The quick way: one setup command

If you'd rather not do the next two sections by hand, run this once:

```bash
bash ~/SIO221a_Github_code_2026/tools/sio221a-setup
```

It creates the conda environment, installs everything including the MATLAB kernel,
and adds a `sio221a` command to your shell that launches JupyterLab correctly. Then
open a **new** terminal and type `sio221a`.

It's safe to run more than once, and it's the fastest way to set up a second computer.
You still need MATLAB itself installed if you want the MATLAB notebooks.

### Python users

Install [Miniconda](https://docs.conda.io/en/latest/miniconda.html), then:

```bash
conda create -n sio221a python=3.11
conda activate sio221a
pip install jupyterlab numpy scipy matplotlib netCDF4 xarray pandas
jupyter lab
```

### MATLAB users

You need MATLAB R2020b or newer, installed and licensed — UCSD provides it free
through the Total Academic Headcount licence, so don't pay for it. Then, **in the
same conda environment as above**:

```bash
pip install jupyter-matlab-proxy
```

On an **Intel Mac** add a pin, or this step fails with a long Rust compile error —
see [TROUBLESHOOTING.md](TROUBLESHOOTING.md). (`uname -m` tells you: `x86_64` is
Intel, `arm64` is Apple Silicon. The setup script above handles this for you.)

```bash
pip install --only-binary cryptography 'cryptography<49' jupyter-matlab-proxy
```

That is MathWorks' [official Jupyter integration](https://github.com/mathworks/jupyter-matlab-proxy).
It registers a kernel called `jupyter_matlab_kernel`, which is what the MATLAB
notebooks here ask for. Choose **MATLAB Kernel** from the kernel menu.

Two things reliably trip people up:

- **Launch JupyterLab from the environment where you installed it.** The kernel
  starts a helper program, `matlab-proxy-app`, that lives inside that environment.
  If it isn't on your `PATH` you get the unhelpful error
  `Failed to create matlab-proxy subprocess`. So `conda activate sio221a` *before*
  `jupyter lab`, every time.
- **The kernel asks you to sign in to MathWorks the first time.** If MATLAB is
  already activated on your machine, skip that by setting
  `MWI_USE_EXISTING_LICENSE=True` before launching.

Or just use the launcher in this repo, which handles both:

```bash
~/SIO221a_Github_code_2026/tools/sio221a-lab
```

**If setup goes wrong**, read [TROUBLESHOOTING.md](TROUBLESHOOTING.md) before
improvising a fix. It covers the failures that have actually bitten people on this
course, including a couple whose error messages point nowhere near the real cause.

---

## What's in here

| Path | Contents |
|---|---|
| `data/` | The data sets used in lectures and homework |
| `mha_code/` | Shared MATLAB routines. The setup cell adds this to your path |
| `python_code/` | Python counterparts of the same routines |
| `tools/` | `sio221a-lab`, a launcher that starts JupyterLab with a working MATLAB kernel |
| `homework/` | Data for the problem sets |
| `coding-exercises/` | Prompts for the in-class group exercises |

**Lecture notebooks are distributed through Canvas**, not from this repository -
they are revised right up until each class. Put them wherever you like; the setup
cell finds this repo independently of where the notebook sits.

Every notebook opens with the same **standard setup cell**. It locates your clone,
puts the class routines on your path, and prints where it found things. If it can't
find the repo it stops with a message telling you what to fix.

---

## Submitting your work

**Please don't push your homework to this repository.** Fork it, work in your fork,
and open a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full recipe —
that workflow is itself part of what you're learning in this course.

---

## Data sources and attribution

The data here are redistributed for teaching. Please cite the original providers if
you use them for anything beyond coursework.

- `data/scripps_pier-*.nc` — Scripps Pier shore station, from the
  [Southern California Coastal Ocean Observing System (SCCOOS)](http://sccoos.org/data/autoss/).
- `homework/HW5_data/OS_T8S110W_*.nc` — Tropical Atmosphere Ocean (TAO) array
  moored buoy winds, NOAA/National Data Buoy Center.
- `data/eps_BLT_example.mat`, `data/class10_record.*` — example excerpts from
  research data collected by the Alford group.

## Licence

Code in this repository is released under the [MIT Licence](LICENSE). The lecture
notes and figures are the instructor's course material; the data belong to the
providers listed above and carry their own terms.

---

*Matthew Alford and Sarah Gille — Scripps Institution of Oceanography*
