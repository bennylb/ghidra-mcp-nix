# This is the single entrypoint for release updates. Fetch sources by immutable
# commits; tag names and tag objects are retained only as provenance.
{
  ghidraMcp = {
    version = "5.14.2";
    requiredGhidraVersion = "12.1.2";

    source = {
      owner = "bethington";
      repo = "ghidra-mcp";
      tag = "v5.14.2";
      rev = "f4a1175b23f797cb19fb0f66c4ba19ff72684e72";
      tagObject = "bbfed0e02b64f0f93f6d448b75ca4d391d0dddca";
      hash = "sha256-2EMETCttJAz53GQaJDHtegb8+T2cHKmHZVMPrV5Cwxc=";
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
