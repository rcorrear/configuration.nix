{
  fetchPypi,
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "graphify";
  version = "0.9.13";
  pyproject = true;

  src = fetchPypi {
    pname = "graphifyy";
    inherit version;
    hash = "sha256-C8OG/UEBWy+rBPkifVJRBkUNir0+PZLzh8T7IwEBOA0=";
  };

  build-system = [
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    python3Packages.pythonRelaxDepsHook
  ];

  dependencies =
    with python3Packages;
    [
      networkx
      numpy
      rapidfuzz
      tree-sitter
    ]
    ++ (with python3Packages.tree-sitter-grammars; [
      tree-sitter-bash
      tree-sitter-c
      tree-sitter-c-sharp
      tree-sitter-cpp
      tree-sitter-clojure
      tree-sitter-elixir
      tree-sitter-fortran
      tree-sitter-go
      tree-sitter-groovy
      tree-sitter-java
      tree-sitter-javascript
      tree-sitter-json
      tree-sitter-julia
      tree-sitter-kotlin
      tree-sitter-lua
      tree-sitter-nix
      tree-sitter-objc
      tree-sitter-php
      tree-sitter-powershell
      tree-sitter-python
      tree-sitter-ruby
      tree-sitter-rust
      tree-sitter-scala
      tree-sitter-swift
      tree-sitter-typescript
      tree-sitter-verilog
      tree-sitter-zig
    ]);

  pythonRelaxDeps = [
    "tree-sitter-fortran"
    "tree-sitter-groovy"
    "tree-sitter-julia"
    "tree-sitter-kotlin"
  ];

  pythonImportsCheck = [
    "graphify"
    "graphify.extractors.clojure"
    "graphify.clojure_resolution"
    "graphify.extractors.nix"
  ];

  postPatch = ''
        cp ${./clojure.py} graphify/extractors/clojure.py
        cp ${./clojure_resolution.py} graphify/clojure_resolution.py
        cp ${./nix.py} graphify/extractors/nix.py

        substituteInPlace graphify/extract.py \
          --replace-fail \
            'from graphify.extractors.csharp import (' \
            'from graphify.extractors.clojure import extract_clojure  # noqa: F401
    from graphify.extractors.nix import extract_nix  # noqa: F401
    from graphify.extractors.csharp import (' \
          --replace-fail \
            'from .ruby_resolution import resolve_ruby_member_calls' \
            'from .ruby_resolution import resolve_ruby_member_calls
    from .clojure_resolution import resolve_clojure_calls' \
          --replace-fail \
            '".java": "jvm", ".kt": "jvm", ".kts": "jvm",' \
            '".java": "jvm", ".kt": "jvm", ".kts": "jvm",
        ".clj": "clojure", ".cljs": "clojure", ".cljc": "clojure",' \
          --replace-fail \
            '".go": extract_go,' \
            '".go": extract_go,
        ".clj": extract_clojure,
        ".cljs": extract_clojure,
        ".cljc": extract_clojure,
        ".nix": extract_nix,' \
          --replace-fail \
            '".go": "go",' \
            '".go": "go",
        ".nix": "nix",' \
          --replace-fail \
            'register_language_resolver(
        LanguageResolver("java_member_calls", frozenset({".java"}), _resolve_java_member_calls)
    )' \
            'register_language_resolver(
        LanguageResolver("java_member_calls", frozenset({".java"}), _resolve_java_member_calls)
    )
    register_language_resolver(
        LanguageResolver("clojure_calls", frozenset({".clj", ".cljs", ".cljc"}), resolve_clojure_calls)
    )'

        substituteInPlace graphify/detect.py \
          --replace-fail \
            "CODE_EXTENSIONS = {'.py'," \
            "CODE_EXTENSIONS = {'.clj', '.cljs', '.cljc', '.nix', '.py',"
  '';

  meta = {
    description = "AI coding assistant skill that turns folders into queryable knowledge graphs";
    homepage = "https://github.com/Graphify-Labs/graphify";
    changelog = "https://github.com/Graphify-Labs/graphify/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "graphify";
    platforms = lib.platforms.unix;
  };
}
