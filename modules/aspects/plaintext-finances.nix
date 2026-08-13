_: {
  den.aspects.plaintext-finances = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.rcorrear.finzytrack

          pkgs.beancount
          pkgs.beancount-black
          pkgs.beancount-language-server
          pkgs.fava
        ];
      };
  };
}
