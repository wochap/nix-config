// Follows a growing JSONL file: each call returns the complete lines
// appended since the last call.

import { closeSync, existsSync, openSync, readSync, statSync } from "node:fs";
import { StringDecoder } from "node:string_decoder";

/** From the start, or from the current end with `fromEnd`. */
export function tail(path: string, fromEnd = false): () => string[] {
  let offset = fromEnd && existsSync(path) ? statSync(path).size : 0;
  let buf = "";
  const decoder = new StringDecoder("utf8");
  const chunk = Buffer.alloc(64 * 1024);
  return () => {
    if (!existsSync(path)) return [];
    const fd = openSync(path, "r");
    let n: number;
    while ((n = readSync(fd, chunk, 0, chunk.length, offset)) > 0) {
      offset += n;
      buf += decoder.write(chunk.subarray(0, n));
    }
    closeSync(fd);
    const lines = buf.split("\n");
    buf = lines.pop() ?? "";
    return lines.filter(Boolean);
  };
}
