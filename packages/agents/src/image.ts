// Images attached to a prompt (run --image, serve's image_url parts).
// Supported: what both claude and pi accept.

export const IMAGE_TYPES = ["image/png", "image/jpeg", "image/gif", "image/webp"] as const;
export type ImageType = (typeof IMAGE_TYPES)[number];

/** Claude's API limit on one image's base64; pi resizes, claude fails the turn. */
export const MAX_IMAGE_BASE64 = 5 * 1024 * 1024;
export const MAX_IMAGES = 20;

/** Mime type from magic bytes; null when not a supported image. */
export function sniff(bytes: Uint8Array): ImageType | null {
  const ascii = (from: number, to: number) => String.fromCharCode(...bytes.subarray(from, to));
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return "image/jpeg";
  if (ascii(1, 4) === "PNG" && bytes[0] === 0x89) return "image/png";
  if (ascii(0, 3) === "GIF") return "image/gif";
  if (ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return "image/webp";
  return null;
}

export const extension = (type: ImageType) => type.slice("image/".length);

/** Reads and checks an image file; throws a one-line error otherwise. */
export async function readImage(path: string): Promise<{ type: ImageType; base64: string }> {
  const bytes = new Uint8Array(await Bun.file(path).arrayBuffer());
  const type = sniff(bytes);
  if (!type) throw new Error(`${path}: not a ${IMAGE_TYPES.map(extension).join("/")} image`);
  const base64 = Buffer.from(bytes).toString("base64");
  if (base64.length > MAX_IMAGE_BASE64) throw new Error(`${path}: image over ${MAX_IMAGE_BASE64 / 1024 / 1024} MiB base64`);
  return { type, base64 };
}
