_: {
  den.aspects.plaintext-finances = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.beancount
          pkgs.beancount-black
          pkgs.beancount-language-server
          pkgs.fava
        ];
      };
  };
}
