{
  description = "nix fizz buzz";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (builtins) toString toJSON;
        inherit (pkgs) runCommand writeText;
        inherit (pkgs.lib) mod runTests;

        source = [ 1 2 3 4 5 6 7 8 9 0 11 12 13 14 15 16 17 18 19 20 ];

        fizzBuzz = n:
          if mod n 15 == 0 then
            "fizzbuzz"
          else if mod n 3 == 0 then
            "fizz"
          else if mod n 5 == 0 then
            "buzz"
          else
            toString n;

      in {
        checks = {
          ut = let
            results = runTests {
              test_fizz = {
                expr = fizzBuzz 3;
                expected = "fizz";
              };
              test_buzz = {
                expr = fizzBuzz 5;
                expected = "buzz";
              };
              test_fizzbuzz = {
                expr = fizzBuzz 15;
                expected = "fizzbuzz";
              };
              test_other = {
                expr = fizzBuzz 1;
                expected = "1";
              };
            };
          in runCommand "ut" { } ''
            mkdir $out
            ${if results != [ ] then ''
              echo "failed test. see '${
                writeText "errors.json" (toJSON results)
              }'"
              exit 1
            '' else ''
              echo "all tests passed!"
              exit 0
            ''}
          '';
        };

        packages.default = pkgs.writeShellApplication {
          name = "fizz-buzz-nix";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            echo '${toJSON (map fizzBuzz source)}' | jq .
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/fizz-buzz-nix";
        };
      });
}
