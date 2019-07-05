[
  line_length: 120,
  inputs: ["*.{ex,exs}", "{config,lib,priv,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: [resolve: :*, arg: :*, puts: :*, defenum: :*, attributes: :*]
]
