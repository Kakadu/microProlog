(lang dune 3.5)

(generate_opam_files true)

(name MicroProlog)

(package
 (name MicroProlog)
 (synopsis "Minimal implementation of Prolog with SLD resolution")
 (maintainers "Kakadu@pm.me")
 (authors "dboulytchev@gmail.com")
 (homepage "https://github.com/Kakadu/microProlog")
 (bug_reports "https://github.com/dboulytchev/microProlog")
 (depends
  ostap
  GT
  ;
  ))
