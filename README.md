# MEV Package
This is a [Kurtosis package](https://docs.kurtosis.com/concepts-reference/packages). This package spins up

1. MEV Relay and Dependencies - Postgres & Redis
2. MEV Relay Housekeeper
3. MEV Relay Website
4. MEV Boost
5. MEV Flood

As of 2023-07-21 this package is set to spin up Mock MEV instead of the full stack above which would spin up

1. Mock MEV builder by Ethereum Foundation
2. MEV Boost

Use this package in your package
--------------------------------
Kurtosis packages can be composed inside other Kurtosis packages. To use this package in your package:

<!-- TODO Replace YOURUSER and THISREPO with the correct values! -->
First, import this package by adding the following to the top of your Starlark file:

```python
this_package = import_module("github.com/kurtosis-tech/mev-package/lib/mev_launcher.star")
```

Then, call the this package's `run` function somewhere in your Starlark script:

```python
this_package_output = this_package.run(plan, el_context, cl_context, network_params)
```

For an example of using this package with other packages, check out the example in the Geth Lighthouse package:
https://github.com/kurtosis-tech/geth-lighthouse-package

Develop on this package
-----------------------
1. [Install Kurtosis][install-kurtosis]
1. Clone this repo
1. For your dev loop, run `kurtosis clean -a && kurtosis run .` inside the repo directory


<!-------------------------------- LINKS ------------------------------->
[install-kurtosis]: https://docs.kurtosis.com/install
[enclaves-reference]: https://docs.kurtosis.com/concepts-reference/enclaves
