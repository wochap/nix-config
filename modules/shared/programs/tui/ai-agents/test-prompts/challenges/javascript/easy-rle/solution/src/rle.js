export function encode(text) {
  let out = "";
  let prev;
  let count = 0;
  for (const ch of text) {
    if (ch === prev) {
      count++;
      continue;
    }
    if (count > 0) out += `${count}${prev}`;
    prev = ch;
    count = 1;
  }
  if (count > 0) out += `${count}${prev}`;
  return out;
}

export function decode(text) {
  let out = "";
  let digits = "";
  for (const ch of text) {
    if (ch >= "0" && ch <= "9") {
      if (digits === "" && ch === "0") throw new SyntaxError("bad count");
      digits += ch;
      continue;
    }
    if (digits === "") throw new SyntaxError(`missing count before ${ch}`);
    out += ch.repeat(Number.parseInt(digits, 10));
    digits = "";
  }
  if (digits !== "") throw new SyntaxError("count without character");
  return out;
}
