{
  writeShellApplication,
  jq,
}:

# `summary` and `omniroute-chat` come from the system profile (ai and
# omniroute modules); this tool only adapts article JSON to them.
writeShellApplication {
  name = "article-summarize";
  runtimeInputs = [ jq ];
  text = builtins.readFile ./article-summarize.sh;
  meta.description = "Summarize article-scrape JSON as Markdown through OmniRoute";
}
