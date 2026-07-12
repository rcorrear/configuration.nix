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

  pythonImportsCheck = [ "graphify" ];

  meta = {
    description = "AI coding assistant skill that turns folders into queryable knowledge graphs";
    homepage = "https://github.com/Graphify-Labs/graphify";
    changelog = "https://github.com/Graphify-Labs/graphify/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "graphify";
    platforms = lib.platforms.unix;
  };
}
