# This is the single entrypoint for release updates. Fetch sources by immutable
# commits; tag names and tag objects are retained only as provenance.
{
  ghidraMcp = {
    version = "6.0.0";
    requiredGhidraVersion = "12.1.2";

    source = {
      owner = "bethington";
      repo = "ghidra-mcp";
      tag = "v6.0.0";
      rev = "8cd2078e10b9ba28b188cb84ce5b9051a904b995";
      tagObject = "65acb75a2c6671885541c2989e7f9aa3c9bae54a";
      hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
    };
  };

  # No upstream tags or releases: pinned by commit only.
  ghidraTables = {
    source = {
      owner = "daskey";
      repo = "GhidraTables";
      rev = "b1af2b617e55d9499d187e6d414fb3c9da159765";
      hash = "sha256-uWuw6NSROSGEH34e02bEC8XuV7jLs9wtuGBbPvt7Gec=";
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
