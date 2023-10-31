{ lib
, buildGoModule
, fetchFromGitHub
, iproute2
, iptables
, makeWrapper
, procps
,
}:
buildGoModule rec {
  pname = "gvisor";
  version = "20231030.0";

  # gvisor provides a synthetic go branch (https://github.com/google/gvisor/tree/go)
  # that can be used to build gvisor without bazel.
  # For updates, you should stick to the commits labeled "Merge release-** (automated)"

  src = fetchFromGitHub {
    owner = "google";
    repo = "gvisor";
    rev = "c07ea5ab2ead274ddb84399d9eb6d7c5652b9e4b";
    sha256 = "sha256-NYSgjqMkOSM0faJyd4lH/mYnI/azfbs9gk3nlsB5C/s=";
  };

  preBuild = ''
    GOPROXY=https://proxy.golang.org go mod vendor
  '';

  vendorHash = "sha256-+QFaVtpf17Z4KRF9SyoQc0vWFrb0A4OwCrbqxL5b+8M=";

  nativeBuildInputs = [ makeWrapper ];

  CGO_ENABLED = 0;

  ldflags = [ "-s" "-w" ];

  subPackages = [ "runsc" "shim" ];

  postInstall = ''
    # Needed for the 'runsc do' subcommand
    wrapProgram $out/bin/runsc \
      --prefix PATH : ${lib.makeBinPath [iproute2 iptables procps]}
    mv $out/bin/shim $out/bin/containerd-shim-runsc-v1
  '';

  meta = with lib; {
    description = "Application Kernel for Containers";
    homepage = "https://github.com/google/gvisor";
    license = licenses.asl20;
    maintainers = with maintainers; [ andrew-d gpl ];
    platforms = [ "x86_64-linux" ];
  };
}
