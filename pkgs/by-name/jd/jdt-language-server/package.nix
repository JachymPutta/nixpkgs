{
  lib,
  stdenv,
  fetchurl,
  python3,
  jdk,
}:

let
  timestamp = "202506271502";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "jdt-language-server";
  version = "1.48.0";

  src = fetchurl {
    url = "https://download.eclipse.org/jdtls/milestones/${finalAttrs.version}/jdt-language-server-${finalAttrs.version}-${timestamp}.tar.gz";
    hash = "sha256-sKf6EkDiyvEpbVnqcJxSXUpjH779pJ5xguB+AMHeYsk=";
  };

  sourceRoot = ".";

  buildInputs = [
    # Used for the included wrapper
    python3
  ];

  postPatch = ''
    # We store the plugins, config, and features folder in different locations
    # than in the original package. In addition, hard-code the path to the jdk
    # in the wrapper, instead of searching for it in PATH at runtime.
    substituteInPlace bin/jdtls.py \
      --replace-fail "jdtls_base_path = Path(__file__).parent.parent" "jdtls_base_path = Path(\"$out/share/java/jdtls/\")" \
      --replace-fail "java_executable = get_java_executable(known_args)" "java_executable = '${lib.getExe jdk}'"
  '';

  installPhase =
    let
      # The application ships with different config directories for each platform.
      # Note the application come with ARM variants as well, although the
      # current included wrapper doesn't use them.
      configDir = if stdenv.hostPlatform.isDarwin then "config_mac" else "config_linux";
    in
    ''
      runHook preInstall

      install -Dm444 -t $out/share/java/jdtls/plugins/ plugins/*
      install -Dm444 -t $out/share/java/jdtls/features/ features/*
      install -Dm444 -t $out/share/java/jdtls/${configDir} ${configDir}/*
      install -Dm555 -t $out/bin bin/jdtls
      install -Dm444 -t $out/bin bin/jdtls.py

      runHook postInstall
    '';

  passthru.updateScript = ./update.sh;

  meta = {
    homepage = "https://github.com/eclipse/eclipse.jdt.ls";
    description = "Java language server";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.epl20;
    maintainers = with lib.maintainers; [ matt-snider ];
    platforms = lib.platforms.all;
    mainProgram = "jdtls";
  };
})
