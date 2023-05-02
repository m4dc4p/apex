{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs/release-22.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  nixConfig = {
    bash-prompt-prefix = "develop >";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    let
      systems = flake-utils.lib.defaultSystems;
    in
      flake-utils.lib.eachSystem systems (system: 
        let 
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) python3 python3Packages;
          localPkg = python3Packages.buildPythonPackage {
            name = "apex";
            version = "0.0.1";
            src = ./.;
            doCheck = false;
            doInstallCheck = false;
            nativeBuildInputs = with python3Packages; [ setuptools-scm 
                cxxfilt
                numpy
                pyyaml
                pytest
                packaging
                torch
                pkgs.cudaPackages.cuda_nvcc
              ];
            preBuild = ''
                export CUDA_HOME=${pkgs.cudaPackages.cuda_nvcc}
                export TORCH_CUDA_ARCH_LIST="6.0"
              '';
            postBuild = ''
                export CUDA_HOME=${pkgs.cudaPackages.cuda_nvcc}
                export TORCH_CUDA_ARCH_LIST="6.0"
                pip install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" --global-option="--fast_layer_norm" --global-option="--distributed_adam" --global-option="--deprecated_fused_adam" ./
              '';
            };
          shell = pkgs.mkShell {
              packages = [  ];
              buildInputs =  [ localPkg ];
              shellHook = ''
                export CUDA_HOME=${pkgs.cudaPackages.cuda_nvcc}
              '';
            };         
        in 
          { 
            devShell = shell;
            devShells.default = shell;
          }
      );
}
