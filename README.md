# GroupReputations.jl

Package for simulating evolutionary dynamics of populations using individual and group reputations.

For installation, in Julia REPL:
```
] add https://github.com/michel-mata/GroupReputations.jl.git
```

### Module

The module structure is:
```
src
├── GroupReputations.jl
└── module
    ├── methods
    │   ├── evolution.jl
    │   ├── get_functions.jl
    │   └── simulation.jl
    └── structs.jl
```

Where:
- `GroupReputations.jl`: contains the main module declaration and exports
- `module/structs.jl`: contains the declaration of relevant structures
- `module/methods/evolution.jl`: contains the functions for the evolutionary dynamics of a population
- `module/methods/get_functions.jl`: contains the functions for measuring statistics and outcomes of the dynamical process
- `module/methods/simulation.jl`: contains the functions for running extensive simulations and sweeping parameters

### Usage

1. When cloning the repository:

Select the number of workers or threads for parallel running,
declare the environment and install needed packages:
```
num_workers = 8
include("./setup.jl")
```
