(lang dune 2.9)
(using menhir 2.0)
(using dune_site 0.1)
(cram enable)
(name schmu)

(authors "Tobias Mock")
(maintainers "tobiasjammer@gmail.com")

(generate_opam_files true)

(package
 (name schmu)
 (version 0.1)
 (description
  "A functional programming language focused on a simple and practical core")
 (depends
  (pp_loc (>= 2.0.0))
  (alcotest (and (>= 1.5.0) :with-test))
  (dune-site (>= 2.9))
  (menhir (>= 20211230))
  (menhirLib (>= 20211230))
  (ppx_deriving (>= 5.2.1))
  (llvm (and (>= 16.0.0) (< 17.0.0)))
  (sexplib0 (>= v0.15.0))
  (ppx_sexp_conv (>= v0.15.0)))
 (sites (lib std)))
