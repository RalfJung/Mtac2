# Mtac2

A typed tactic language for Coq.

Copyright (c) 2018 Jan-Oliver Kaiser <janno@mpi-sws.org>
                   Beta Ziliani <beta@mpi-sws.org>

Distributed under the terms of the MIT License,
see LICENSE for details.

This archive is a plugin for Coq containing the new tactic language
described in the outdated paper
[The Next 700 Safe Tactic Languages](http://www.mpi-sws.org/~beta/#publications).


The archive has 3 subdirectories:
* `src` contains the code of the plugin.
  - `run.ml` is the interpreter.

* `theories` contains support Coq files for the plugin.
  - `Mtac2.v` declares the plugin on the Coq side and imports all the
     required theories.
  - `intf` contains the basics: the `M` monad, exceptions, etc.
  - `Tactics.v` defines the tactic type and several tactics and combinators.
  - `Ttactics.v` defines the type for typed tactics and combinators.
  - `IntroPatt.v` defines intro patterns.
  - `ConstrSelector.v` defines a selector based on the indices of an
    inductive type's constructors.

* `test-suite` contains several tests, including some uses of the plugin.

Installation
============

The plugin works currently with Coq v8.7 (and any minor version). It requires
[UniCoq](http://github.com/unicoq/unicoq) to be
installed. Mtac2 will be available in OPAM soon.
For the moment you should have coqc, ocamlc and make in your path.
Then simply do:
```
 coq_makefile -f _CoqProject -o Makefile
```
To generate a makefile from the description in `_CoqProject`, then `make`.
This will consecutively build the plugin and the supporting
theories.

You can then either `make install` the plugin or leave it in its
current directory. To be able to import it from anywhere in Coq,
simply add the following to `~/.coqrc`:
```
Add LoadPath "path_to_unicoq/theories" as Mtac2.
Add ML Path "path_to_unicoq/src".
```
# Usage

Once installed, you can `Require Import Mtac2.Mtac2` to load the
plugin. The plugin defines a tactic `mrun t` to execute code `t` and a proof
mode `MProof` where Mtac2's tactic can be executed directly.
