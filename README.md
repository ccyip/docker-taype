# Introduction

This is the artifact for the OOPSLA 2024 paper "Taypsi: Static Enforcement of
Privacy Policies for Policy-Agnostic Oblivious Computation". It provides the
source code of the Taypsi language and the lifting algorithm described in the
paper, Coq formalization of Taypsi core calculus in Section 3, and benchmarks
for reproducing the experimental results in Section 6.

We have made the following claims in the paper.
- The presented core calculus is mechanized in Coq, including the proofs of
  soundness and oblivious theorems. See [Coq formalization of the core
  calculus](#coq-formalization-of-the-core-calculus) for instructions on how to
  validate this claim.
- Taypsi performs considerably better than Taype on many benchmarks, and works
  roughly as well on the remainer. In addition, the compilation overhead is
  reasonable. See [Reproduce the experimental
  results](#reproduce-the-experimental-results) for instructions on how to
  reproduce the experimental results that support this claim.

The running example in Section 2 is also available in the artifact. See
[Correspondence between paper and
artifact](#correspondence-between-paper-and-artifact).

# Hardware Dependencies

We provide the artifact as docker images for amd64 (x86-64) and arm64
architectures. Thus, any hardware of these two architectures should work, as
long as the installed operating system is supported by docker. However, to fully
reproduce our experimental results, you need at least 8 GB of memory. You also
need around 14 GB of storage space to load the docker image (after downloading
it).

We have tested this artifact on a x86-64 Linux box and an Apple Silicon (M1)
Mac.

# Getting Started Guide

This artifact is a docker image, which contains:
- This README file, located at `~/README.md`.
- The docker file used to generate the docker images, located at `~/Dockerfile`.
- The implementation of the Taypsi type checker and compiler, based on [Taype
  (PLDI23)](https://doi.org/10.1145/3591261), located at `~/taypsi`. ([Github
  repository](https://github.com/ccyip/taype/tree/oopsla24))
- The implementation of the Taype type checker and compiler (PLDI23), located at
  `~/taype-pldi`. It is extended with additional benchmarks for the comparison
  in the evaluation section. ([Github
  repository](https://github.com/ccyip/taype/tree/tape))
- The implementation of a version of Taype with an additional optimization
  (smart array) for a fairer comparison, located at `~/taype-sa`. Note that the
  result of this experiment is not in the current submission, but will be
  included in the final version of the paper. ([Github
  repository](https://github.com/ccyip/taype/tree/tape-sa))
- All examples and experiments from the paper, located at `~/taypsi/examples`
  (correspondingly `~/taype-pldi/examples` and `~/taype-sa/examples`).
- Coq formalization of the Taypsi core calculus, based on [Oblivious Algebraic
  Data Types (POPL22)](https://doi.org/10.1145/3498713), located at
  `~/taypsi-theories`. ([Github
  repository](https://github.com/ccyip/oadt/tree/oopsla24))
- The source code of drivers that implement the cryptographic primitives and
  oblivious array, located at `~/taype-drivers`. This implementation includes
  the smart array optimization, and is used by Taypsi (`~/taypsi`) and the
  version of Taype with smart array optimization (`~/taype-sa`). ([Github
  repository](https://github.com/ccyip/taype-drivers/tree/oopsla24))
- The source code of the drivers from Taype (PLDI23), located at
  `~/taype-drivers-legacy`. This implementation is used by Taype
  (`~/taype-pldi`). ([Github
  repository](https://github.com/ccyip/taype-driver-emp))
- A [code-server](https://github.com/coder/code-server) (VS Code in the
  browser), so that we can view source code simply in a browser (this is not
  required, of course). We pre-installed a few VS Code extensions:
  + Taype: for reading Taypsi source code. This extension provides basic syntax
    highlighting for Taypsi and its intermediate language OIL. (The name of this
    extension is still called Taype as Taypsi is based on and is an extension of
    Taype.)
  + Haskell: for reading source code of the Taypsi type checker and compiler,
    which is implemented in Haskell.
  + OCaml: for reading source code of the generated OCaml programs, test cases
    and part of the source code of Taypsi. Since Taypsi programs are compiled to
    OCaml libraries, our test cases are also written in OCaml, which handle I/O
    and invoke these libraries. The constraint solver presented in the paper is
    also implemented in OCaml.
  + VsCoq: for reading Coq formalization.
  + Python: for reading the script that interprets the evaluation results and
    generates LaTeX tables.

All the implementations in the docker image have been pre-compiled. The clean
version of the source code, this README file and the docker file are also
available on [Zenodo](https://doi.org/10.5281/zenodo.10443796).

To evaluate this artifact, first install [docker](https://www.docker.com/), and
then download one of our docker images from Zenodo, depending on your machine's
architecture. We provide images for amd64 (i.e. x86-64) and arm64 (e.g., for
Apple Silicon Mac). You need around 14 GB of storage space to load them, and 8
GB of RAM for the container to run the experiments.

Now you can load and run the downloaded docker image. The following commands
create an image called `taypsi-image`, and start a container called `taypsi`. We
also expose the port `8080` for accessing the code-server.

``` sh
# <arch> is amd64 or arm64
mv taypsi-image-<arch>.tar.xz taypsi-image.tar.xz
# This command will take a minute or two
docker load -i taypsi-image.tar.xz
docker run -dt -p 8080:8080 -m 8g --name taypsi taypsi-image
```

The docker container is allocated 8 GB of memory which is the memory cap used in
the evaluation section. You could allocate a smaller amount of memory if 8 GB is
not possible, but you would not be able to completely reproduce the experimental
results (more benchmarks may fail). You need around 2 GB to compile the Coq
formalization.

To launch the code-server, run:

``` sh
docker exec -d taypsi code-server
```

Now we can open the URL [localhost:8080](http://localhost:8080) (or
[127.0.0.1:8080](http://127.0.0.1:8080)) in a browser to access VS Code. Note
that some functionality may not work if you use private mode or incognito mode.
You may read this markdown file (`~/README.md`) with a nicely rendered preview.
We did not pre-install the Haskell language server or the OCaml language server
in the docker image, but you can install them (more instructions are available
in the [next section](#step-by-step-instructions)). You may install other
extensions too.

To access the container shell, run

``` sh
docker exec -it taypsi bash --login
```

Your user name is `reviewer` (without password) and the current directory is `~`
(i.e. `/home/reviewer`). In the rest of this document, we assume commands are
run inside the container.

To quickly test this artifact, compile the tutorial example and run its test
cases. The Taypsi source file of this example
`taypsi/examples/tutorial/tutorial.tp` also contains a lot of comments on how to
write Taypsi programs and oblivious types.

``` sh
cd taypsi
cabal run shake -- run/tutorial
```

We will explain what exactly this command is doing in the next section, but you
should see the output of the tests, which contains headers like:

`== Test case 1 (round 1) ==`

and then a few numbers for the performance statistics.


# Step-by-Step Instructions

This section provides details on how the figures (claims) in the paper
correspond to the implementation, how to reproduce the experimental results, how
to use our tools, and the minor discrepancies between the implementation and the
paper's description.

## How to read code

As mentioned in the previous section, you can read the source code in the
browser with code-server. The docker image also comes with vim, if you prefer
reading source code in the console, but we do not have a syntax highlighting
extension for vim yet.

You may want to install Haskell and OCaml language servers for richer IDE
features such as jump to definition. You can install them by running:

``` sh
# Install Haskell language server
# This step may not be needed, as the Haskell VS Code extension may ask and do this for you
ghcup install hls

# Install OCaml language server
opam install ocaml-lsp-server
```

## Correspondence between paper and artifact

To see how this artifact connects to our approach described in the paper, we
summarize the correspondence in the following table. For presentation purposes,
the Taypsi syntax in the paper uses hat, math symbols and so on, which can not
be typed in the source code, so the concrete syntax is different, which we will
summerize later.

Note that we still use the name Taype (e.g., in file names and module names) in
the Taypsi compiler source code, as Taypsi is based on Taype and is an extension
of Taype.

| In paper | In artifact | Comment |
| -------- | ----------- | ------- |
| Fig. 1 | `list` and `filter` in `taypsi/examples/tutorial/tutorial.tp` | |
| Fig. 2 | `~list` and `~list_eq` in `taypsi/examples/tutorial/tutorial.tp` | |
| Fig. 3 | `~list#s`, `~list#r`, `~list#view`, `~list#Nil`, `~list#Cons`, `~list#match`, `~list#join` and `~list#reshape` in `taypsi/examples/tutorial/tutorial.tp` | |
| Figures and theorems in Section 3 | See [Coq formalization of the core calculus](#coq-formalization-of-the-core-calculus) | |
| Fig. 13 | `liftDefs` in `taypsi/src/Taype/Lift.hs` | See Note 1 |
| Fig. 14 | `Ppx` in `taypsi/src/Taype/Syntax.hs` and `elabPpx` in `taypsi/src/Taype/TypeChecker.hs` | Typed macros are called preprocessors (ppx) in source code |
| Fig. 15 | `Constraint` in `taypsi/src/Taype/Lift.hs` | |
| Fig. 16 | `liftExpr` in `taypsi/src/Taype/Lift.hs` | |
| Compilation and optimizations in Section 6 | Source code in `taypsi` and `taype-drivers` | See Note 2 |
| Figures in Section 6 | See [Reproduce the experimental results](#reproduce-the-experimental-results) | |

Notes:
1. While the entry point of the lifting algorithm is `liftDefs` in
   `taypsi/src/Taype/Lift.hs`, some subroutines are implemented in other files.
   Constraint solver is implemented in `taypsi/solver/bin/solver.ml` and
   `taypsi/solver/lib/solver.ml`. Elaboration of typed macros is `elabPpx` in
   `taypsi/src/Taype/TypeChecker.hs`.
2. The source code of the bidirectional type checker is in
   `taypsi/src/Taype/TypeChecker.hs`, and the lifting procedure is in
   `taypsi/src/Taype/Lift.hs`, and the translation to OIL is in
   `taypsi/src/Oil/Translation.hs`. The smart array optimization is defined in
   `taype-drivers/lib/smart.ml`. The reshape guard optimization is defined at
   `guardReshape` in `taypsi/src/Oil/Optimization.hs`. The memoization
   optimization is `memo` in `taypsi/src/Oil/Optimization.hs`. The driver used
   in our evaluation is `taype-drivers/emp/taype_driver_emp.ml`. See also
   [Understand the compilation pipeline](#understand-the-compilation-pipeline).

The following table summerizes the syntactic and naming discrepancies between
the Taypsi source code and the listings in the paper.

| In paper | In artifact | Comment |
| -------- | ----------- | ------- |
| `𝟙` | `unit` | Unit type |
| `𝔹` | `bool` | Boolean type |
| `ℤ` | `int` | Integer type |
| `ℕ` | `uint` | Unsigned integer (natural number) type |
| `×` | `*` | Product type former |
| `Ψ` | `#` | Ψ-type, e.g., `#~list` for `Ψlist` with hat |
| `⟨_,_⟩` | `#(_,_)` | Ψ-type pair |
| `𝜆` | `\` | Lambda abstraction, e.g., `\x => ...` for `𝜆x => ...` |
| Name with hat | Prefixed by `~` | e.g., `~list` for `list` with hat |
| Primitive sections and retractions | `~bool#s`, `~bool#r`, `~int#s` and `~int#r` | |
| `match _ with _` | `match _ with _ end` | Pattern matching |

## Coq formalization of the core calculus

We have formalized the Taypsi core calculus described in Section 3 in Coq
(`~/taypsi-theories`), including proofs of the soundness and obliviousness
theorems.

To validate the formalization, run:

```sh
cd taypsi-theories
make clean
make
```

These commands should output two lines stating `Closed under the global
context`. These are generated from the file
`taypsi-theories/theories/lang_taypsi/metatheories.v`, indicating that both of
the key theorems have been proved without any axioms.

You can also read the Coq formalization
[online](https://ccyip.github.io/oadt/taypsi), with nicely rendered
documentation.

The following table summarizes the correspondence between the paper and the Coq
formalization:

| In paper | In artifact | Notations |
| -------- | ----------- | --------- |
| Fig. 4 | `expr`, `gdef`, `otval`, `oval` and `val` in `taypsi-theories/theories/lang_taypsi/syntax.v` | Defined in the `expr_notations` module in the same file |
| Fig. 5 | `step` and `ectx` in `taypsi-theories/theories/lang_taypsi/semantics.v` | `e -->! e'` (or `Σ ⊨ e -->! e'`) for `step` |
| Fig. 6 | `typing` and `kinding` in `taypsi-theories/theories/lang_taypsi/typing.v` | `Γ ⊢ e : τ` (or `Σ; Γ ⊢ e : τ`) for `typing` and `Γ ⊢ τ :: κ` (or `Σ; Γ ⊢ τ :: κ`) for `kinding` |
| Fig. 7 | `gdef_typing` in `taypsi-theories/theories/lang_taypsi/typing.v` | `Σ ⊢₁ D` |
| Theorem 3.1 (Obliviousness) | `obliviousness` in `taypsi-theories/theories/lang_taypsi/metatheories.v` | |

The `soundness` theorem is also available in
`taypsi-theories/theories/lang_taypsi/metatheories.v`.

For simplicity, our mechanization of the core calculus differs slightly from the
one presented in the paper:
- The mechanization includes `fold` and `unfold` operations for recursive ADTs,
  similar to Ye and Delaware (POPL22), instead of the ML-style ADTs in the
  paper. The equivalence between these two styles is well-known (cf. Chapter 20
  of "Types and Programming Languages").
- The mechanization distinguishes between oblivious product (whose components
  must be oblivious) and normal product (whose components can be any types),
  similar to Ye and Delaware (PLDI23). The style in the Taypsi paper is closer
  to Ye and Delaware (POPL22), which includes only one product former that can
  connect any types, for presentation purposes.
- The mechanization uses distinct projections for product and Ψ-type, while the
  paper abuses the notation for presentation.
- The mechanization uses *locally nameless representation* for
  binders.
- There are some notational differences which should be easy to disambiguate: we
  use `case .. of ..` instead of `match .. with ..`, and `mux` instead of `~if`
  (oblivious conditional), for example.


## Reproduce the experimental results

To reproduce Fig. 17, 18 and 19 in the paper, we can simply invoke a script
that runs all benchmarks.

``` sh
# At home directory '~'
./bench.sh
```

This script will run each test case 5 times, take the average of the results,
and write them to the directories `taypsi/examples/output-*`. Finally, this
script will execute `taypsi/examples/figs.py` to generate LaTeX tables to
`taypsi/examples/figs` for the figures in Section 6 and appendix.

Be warned that this script takes a long time to run: maybe up to 2 hours
depending on your machine. You can choose to test fewer rounds, by specifying
the number of rounds to the script. This would of course produce less accurate
results, and it can still take up to 1 hour to run.

``` sh
# Run each test case once
./bench.sh 1
```

You can inspect this script and the scripts it invokes (`bench.sh` in `taypsi`,
`taype-pldi` and `taype-sa`) to understand what benchmark suites are tested with
what options.

The following table sumerizes the correspondence between the generated LaTeX
tables and the figures in Section 6. There are also other LaTeX tables generated
for the appendix.

| In paper | In artifact |
| -------- | ----------- |
| First half (list) of Fig. 17 | `taypsi/examples/figs/list-bench-full.tex` |
| Second half (tree) of Fig. 17 | `taypsi/examples/figs/tree-bench-full.tex` |
| First half (list) of Fig. 18 | `taypsi/examples/figs/list-opt-full.tex` |
| Second half (tree) of Fig. 18 | `taypsi/examples/figs/tree-opt-full.tex` |
| Fig. 19 | `taypsi/examples/figs/compile-stats-full.tex` |

Note that, compared to Fig. 17 in the submission,
`taypsi/example/figs/list-bench-full.tex` and `tree-bench-full.tex` generate an
extra column (Taype-SA), which reports the performance numbers of a version of
Taype with smart array optimization. The column (Taypsi) also includes the
percentage of running time relative to this version of Taype. The goal is to
compare Taype (PLDI23) and Taypsi in a fairer way, by having comparable
optimizations in both approaches to maximize their potential. This result will
be included in the final version of the paper.

You are most likely not getting the exact same numbers as in the paper, because
the performance of these benchmarks vary, depending on the power of your
machine, the cryptographic instructions supported by your CPU and a lot of other
factors, let alone running them in a docker container. However, you should
observe similar comparative results: Taypsi performs significantly better than
Taype on many benchmarks, while doing roughly as well on the remainder.

For the additional column (Taype-SA), all benchmarks that fail in Taype should
also fail in Taype-SA, except for `path_16`, and you should observe comparable
or better performance numbers of Taypsi over Taype-SA for other benchmarks. In
addtion, we have optimized the constraint solver since the submission, so all
benchmark suites in Fig. 19 should be compiled under a few seconds (e.g.,
K-means should take only 2 seconds now, instead of 12 seconds in the
submission).

If you are interested in how the tests are done, see [Understand the
test cases](#understand-the-test-cases).

The following tables provide links to the source code of benchmark suites.

| List microbenchmark | In `taypsi/examples/list/list.tp` |
| ------------------- | ----------- |
| `elem_1000` | `~elem` |
| `hamming_1000` | `~hamming_distance` |
| `euclidean_1000` | `~min_euclidean_distance` |
| `dot_prod_1000` | `~dot_prod` |
| `nth_1000` | `~nth` |
| `map_1000` | `~test_map` |
| `filter_200` | `~test_filter` |
| `insert_200` | `~insert` |
| `insert_list_100` | `~insert_list` |
| `append_100` | `~append` |
| `take_200` | `~take` |
| `flat_map_200` | `~test_concat_map` |
| `span_200` | `~test_span` |
| `partition_200` | `~test_partition` |

| Tree microbenchmark | In `taypsi/examples/tree/tree.tp` |
| ------------------- | ----------- |
| `elem_16` | `~elem` |
| `prob_16` | `~prob` |
| `map_16` | `~test_map` |
| `filter_16` | `~test_filter` |
| `swap_16` | `~swap` |
| `path_16` | `~path` |
| `insert_16` | `~insert` |
| `bind_8` | `~bind` |
| `collect_8` | `~test_collect` |

| Suite in Fig. 19 | In artifact |
| ---------------- | ----------- |
| List | `taypsi/examples/list` |
| Tree | `taypsi/examples/tree` |
| Dating | `taypsi/examples/dating` |
| Medical Data | `taypsi/examples/record` |
| Calculator DSL | `taypsi/examples/calculator` |
| Decision Tree | `taypsi/examples/dtree` |
| K-means | `taypsi/examples/kmeans` |
| Miscellaneous | `taypsi/examples/misc` |
| List (stress) | `taypsi/examples/stress-solver` |

## Understand the compilation pipeline

In this section, we discuss how we can inspect the different stages of the
compilation pipeline.

We use the tutorial `taypsi/examples/tutorial.tp` as a running example, which
includes a lot of comments on how to write Taypsi programs. We compile this file
by invoking the Taypsi compiler:

``` sh
cd taypsi
# The compiler name is still called taype
cabal run taype -- examples/tutorial/tutorial.tp
```

This command will generate a few files in the `examples/tutorial` directory:
- `tutorial.stage0.tpc`: Taypsi programs in administrative normal form (ANF),
  with type annotations fully elaborated. However, the typed macros have not
  been expanded, and the lifting procedure has not been invoked yet.
- `tutorial.lifted.tpc`: lifted programs generated by the lifting algorithm.
  These programs still contain typed macros and type variables, corresponding to
  the "lifted functions with macros & type var." block in Fig. 13.
- `tutorial.constraints.sexp`: constraints (Fig. 15) generated by the lifting
  algorithm, in S-expression format.
- `tutorial.solver.input.sexp`: input to the constraint solver. The constraints
  generated in the previous step have been lowered to formulas in qualifier-free
  finite domain theory.
- `tutorial.solver.log`: constraint solver log. It prints out the formulas fed
  to Z3, statistics information collected by Z3, and each step that the
  constraint solver algorithm has done.
- `tutorial.solver.output.sexp`: output of the constraint solver. It consists of
  the type variable assignments for each lifted function.
- `tutorial.stage1.tpc`: lifted programs with type variables instantiated. These
  programs still contain typed macros, corresponding to the "lifted functions
  with macros" block in Fig. 13.
- `tutorial.stage2.tpc`: final Taypsi programs. All typed macros are fully
  elaborated, corresponding to the "well-typed and correct lifted functions"
  block in Fig. 13.
- `tutorial.oil`: translated OIL programs.
- `tutorial.ml`: translated OCaml programs.

If you try to inspect `tutorial.*.tpc` and `tutorial.oil` to better understand
each step in the pipeline, you may want to disable optimization and print out
the programs in a more readable form (as opposed to ANF).

``` sh
cabal run taype -- --fno-opt --readable examples/tutorial/tutorial.tp
```

You can learn about other options by running `cabal run taype -- --help`.

The Taypsi compiler only generates OCaml code as libraries. To make a runnable
application, we also have to write the "frontends" which handle I/O and other
non-oblivious business. For example, `examples/tutorial/test_elem.ml`, which
includes a lot of comments, showcases how we construct a test case as a runnable
executable.

We use the [Shake build system](https://shakebuild.com/) to streamline the
process of building and testing our examples. For instance,

``` sh
# Clean the tutorial example
cabal run shake -- clean/tutorial
# Compile the tutorial example, and its test cases
# --verbose tells shake to print out the commands being run
cabal run shake -- --verbose build/tutorial
# Run all tutorial test cases
cabal run shake -- run/tutorial
# Run an individual test case
cabal run shake -- run/tutorial/test_elem
# Run a test case with a specific driver (supported drivers are emp and plaintext)
cabal run shake -- run/tutorial/test_elem/plaintext
# See the supported options and targets
cabal run shake -- --help
```

## Understand the test cases

Each of our test cases is implemented as a `test_<name>.ml` file, e.g.,
`examples/tutorial/test_elem.ml`, which is compiled to an executable. These
executables take two arguments (driver and the participating party), and read
inputs from `stdin`. Sample input is available for the tutorial example, and
we can run these executables through the `dune` build system for OCaml.

``` sh
cd taypsi
# Compile the tutorial example first
cabal run shake -- build/tutorial
cd examples/tutorial
# Run the test case with the plaintext driver.
# This driver only supports one party "trusted".
dune exec ./test_elem.exe plaintext trusted < test_elem.input
# Run the test case with the emp driver (based on EMP toolkit).
# It is a two-party computation with alice and bob.
dune exec ./test_elem.exe emp alice < test_elem.alice.input &
dune exec ./test_elem.exe emp bob < test_elem.bob.input
```

The output of these executables is the collected performance statistics. For
plaintext driver, the output is the number of MUXes performed. For emp driver,
the output is the running time in microseconds.

As we are testing the oblivious `~elem` function, the input specifies the public
view, the private list from Alice, the private integer from Bob, and also the
expected result. For example, the file `test_elem.alice.input` is:

``` text
public: 10
alice: (3 4 7)
bob:
expected: false
```

See the comments in `test_elem.ml` for more details. Note that the value of
`bob` is absent (which is 6 in `test_elem.bob.input`), since this is the input
to the party Alice.

The actual inputs for the test cases are organized in a CSV file, e.g.,
`examples/tutorial/test_elem.input.csv`. The first line is the header,
specifying which party the data comes from, and then each line specifies a test
input. For example, the header of `test_elem.input.csv` is
`public,alice,bob,expected`, while one of the test line is `10,(3 4 7),6,false`.
The test runner will launch the test programs for each party and feed them the
corresponding input. The output is then collected into another CSV file, e.g.,
`examples/output/tutorial/test_elem.emp.output.csv`. We can invoke the test runner by:

``` sh
cabal run shake -- run/tutorial
```

## Install dependencies and build the source code from scratch

If you want to install the dependencies and build this project on your own
machine, you can check out the `README.md` files under `taypsi` and
`taype-drivers` directories. Alternatively, the docker file used to build this
docker image is also available (`~/Dockerfile` in the docker container or on
Zenodo).

# Reusability Guide

The Taypsi type checker and compiler (`~/taypsi`) and the Coq formalization of
the Taypsi core calculus (`~/taypsi-theories`) should be evaluated for
reusability.

The tutorial example (`~/taypsi/examples/tutorial`) contains extensive comments
on how to write Taypsi programs and oblivious types
(`~/taypsi/examples/tutorial/tutorial.tp`), and on how to use the generated
OCaml libraries (`~/taypsi/examples/tutorial/test_elem.ml`). You can play with
this example by adding new functions, lifting functions against different
policies, and implementing test cases for the generated private functions. You
can also follow the larger examples (e.g., `dating` and `record`) and implement
a new case study.

The Coq formalization has inline documentation (`coqdoc`), and we can generate
renderred documentation by running:

```sh
cd taypsi-theories
make html
```

A pre-rendered, [online version of this
documentation](https://ccyip.github.io/oadt/taypsi) is also available. 