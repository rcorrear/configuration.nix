{
  fetchPypi,
  lib,
  python3Packages,
}:

let
  # tree-sitter-bash generates bindings through tree-sitter-config. Its
  # datamodel-code-generator dependency currently has Python 3.14 formatting
  # snapshot failures in nixpkgs, unrelated to the generated bindings.
  pythonPackages = python3Packages.overrideScope (
    _final: prev: {
      datamodel-code-generator = prev.datamodel-code-generator.overridePythonAttrs (_: {
        doCheck = false;
      });
    }
  );
  relaxGrammarMetadata =
    grammar:
    grammar.overridePythonAttrs (_: {
      dontCheckPythonMetadata = true;
    });
in
pythonPackages.buildPythonApplication rec {
  pname = "graphify";
  version = "0.9.46";
  pyproject = true;

  src = fetchPypi {
    pname = "graphifyy";
    inherit version;
    hash = "sha256-mveUpS1VD9h+Djw/aMv4FAkQnPEcF1qgCIuyjRAST9o=";
  };

  build-system = [
    pythonPackages.setuptools
  ];

  nativeBuildInputs = [
    pythonPackages.pythonRelaxDepsHook
  ];

  dependencies =
    with pythonPackages;
    [
      networkx
      numpy
      rapidfuzz
      tree-sitter
      watchdog
    ]
    ++ (with pythonPackages.tree-sitter-grammars; [
      (relaxGrammarMetadata tree-sitter-bash)
      (relaxGrammarMetadata tree-sitter-c)
      (relaxGrammarMetadata tree-sitter-c-sharp)
      (relaxGrammarMetadata tree-sitter-cpp)
      (relaxGrammarMetadata tree-sitter-clojure)
      (relaxGrammarMetadata tree-sitter-elixir)
      (relaxGrammarMetadata tree-sitter-fortran)
      (relaxGrammarMetadata tree-sitter-go)
      (relaxGrammarMetadata tree-sitter-groovy)
      (relaxGrammarMetadata tree-sitter-java)
      (relaxGrammarMetadata tree-sitter-javascript)
      (relaxGrammarMetadata tree-sitter-json)
      (relaxGrammarMetadata tree-sitter-julia)
      (relaxGrammarMetadata tree-sitter-kotlin)
      (relaxGrammarMetadata tree-sitter-lua)
      (relaxGrammarMetadata tree-sitter-nix)
      (relaxGrammarMetadata tree-sitter-objc)
      (relaxGrammarMetadata tree-sitter-php)
      (relaxGrammarMetadata tree-sitter-powershell)
      (relaxGrammarMetadata tree-sitter-python)
      (relaxGrammarMetadata tree-sitter-ruby)
      (relaxGrammarMetadata tree-sitter-rust)
      (relaxGrammarMetadata tree-sitter-scala)
      (relaxGrammarMetadata tree-sitter-swift)
      (relaxGrammarMetadata tree-sitter-typescript)
      (relaxGrammarMetadata tree-sitter-verilog)
      (relaxGrammarMetadata tree-sitter-zig)
    ]);

  pythonRelaxDeps = [
    "tree-sitter-bash"
    "tree-sitter-c"
    "tree-sitter-c-sharp"
    "tree-sitter-cpp"
    "tree-sitter-elixir"
    "tree-sitter-fortran"
    "tree-sitter-go"
    "tree-sitter-groovy"
    "tree-sitter-java"
    "tree-sitter-javascript"
    "tree-sitter-json"
    "tree-sitter-julia"
    "tree-sitter-kotlin"
    "tree-sitter-lua"
    "tree-sitter-objc"
    "tree-sitter-php"
    "tree-sitter-powershell"
    "tree-sitter-python"
    "tree-sitter-ruby"
    "tree-sitter-rust"
    "tree-sitter-scala"
    "tree-sitter-swift"
    "tree-sitter-typescript"
    "tree-sitter-verilog"
    "tree-sitter-zig"
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
            'from graphify.extractors.go import _GO_PREDECLARED_FUNCS, extract_go  # noqa: F401' \
            'from graphify.extractors.go import _GO_PREDECLARED_FUNCS, extract_go  # noqa: F401
    from graphify.extractors.clojure import extract_clojure  # noqa: F401
    from graphify.extractors.nix import extract_nix  # noqa: F401' \
          --replace-fail \
            'from .ruby_resolution import resolve_ruby_member_calls' \
            'from .ruby_resolution import resolve_ruby_member_calls
    from .clojure_resolution import resolve_clojure_calls' \
          --replace-fail \
            '".go": "go",' \
            '".go": "go",
        ".clj": "clojure", ".cljs": "clojure", ".cljc": "clojure",
        ".nix": "nix",' \
          --replace-fail \
            '".go": extract_go,' \
            '".go": extract_go,
        ".clj": extract_clojure,
        ".cljs": extract_clojure,
        ".cljc": extract_clojure,
        ".nix": extract_nix,' \
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
    license = lib.licenses.asl20;
    mainProgram = "graphify";
    platforms = lib.platforms.unix;
  };
}
