(lang dune 2.9)
(name schmu)
(using menhir 2.0)
(cram enable)

(authors "Tobias Mock")
(maintainers "tobiasjammer@gmail.com")

(generate_opam_files true)

(package
 (name schmu)
 (version 0.1)
 (description
  "A functional programming language focused on a simple and practical core")
 (depends
  (alcotest (and (>= 1.5.0) :with-test))
  (ppx_deriving (>= 5.2.1))
  (llvm (>= 13.0.0))))
