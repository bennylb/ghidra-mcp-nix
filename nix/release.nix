# This is the single entrypoint for release updates. Fetch sources by immutable
# commits; tag names and tag objects are retained only as provenance.
{
  ghidraMcp = {
    version = "6.0.0";
    # Ghidra release the extension is built against and must match at runtime.
    requiredGhidraVersion = "12.1.4";
    # <ghidra.version> declared by the pinned upstream pom.xml. When it differs
    # from requiredGhidraVersion the pom is retargeted at build time; upstream's
    # own 12.1.2 -> 12.1.4 bumps (#447, #542) changed no Java sources.
    upstreamGhidraVersion = "12.1.2";

    source = {
      owner = "bethington";
      repo = "ghidra-mcp";
      tag = "v6.0.0";
      rev = "8cd2078e10b9ba28b188cb84ce5b9051a904b995";
      tagObject = "65acb75a2c6671885541c2989e7f9aa3c9bae54a";
      hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
    };
  };

  mcpSdk = {
    version = "1.28.1";

    source = {
      owner = "modelcontextprotocol";
      repo = "python-sdk";
      tag = "v1.28.1";
      rev = "777b8d06710c140e3606b0d4598e2aa48546c266";
      hash = "sha256-8nifuun7ShtniimsFr9gYPpjwZEM/5E51GDmZRxQGEc=";
    };
  };
}
