# This is the single entrypoint for release updates. Fetch sources by immutable
# commits; tag names and tag objects are retained only as provenance.
{
  ghidraMcp = {
    version = "7.0.0";
    # Ghidra release the extension is built against and must match at runtime.
    # Provided by the flake's nixpkgs-ghidra input; move the two together.
    requiredGhidraVersion = "12.1.4";

    source = {
      owner = "bethington";
      repo = "ghidra-mcp";
      tag = "v7.0.0";
      rev = "19e64c75f1be1fcbe413e845f65e549f2361b928";
      tagObject = "001145c3a3f2748d8f361a4c60e6b28c11758762";
      hash = "sha256-0RWq1bX3fHY2DR0HQ75ylNCWQbKczvsk8m8/8eSW/Sk=";
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
