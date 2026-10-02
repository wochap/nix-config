export class ValidationError extends Error {
  readonly path: string;

  constructor(path: string, message: string) {
    super(message);
    this.name = "ValidationError";
    this.path = path;
  }
}

export type SafeResult<T> =
  | { success: true; data: T }
  | { success: false; error: ValidationError };

export interface Schema<T> {
  parse(input: unknown): T;
  safeParse(input: unknown): SafeResult<T>;
}

export interface OptionalSchema<T> extends Schema<T | undefined> {
  readonly optional: true;
}

export type Infer<S> = S extends Schema<infer T> ? T : never;

type Shape = Record<string, Schema<unknown>>;

type OptionalKeys<S extends Shape> = {
  [K in keyof S]: S[K] extends OptionalSchema<unknown> ? K : never;
}[keyof S];

type Simplify<T> = { [K in keyof T]: T[K] } & {};

type ObjectOf<S extends Shape> = Simplify<
  { [K in Exclude<keyof S, OptionalKeys<S>>]: Infer<S[K]> } & {
    [K in OptionalKeys<S>]?: Infer<S[K]>;
  }
>;

type Check<T> = (input: unknown, path: string) => T;

function typeName(input: unknown): string {
  if (input === null) return "null";
  if (Array.isArray(input)) return "array";
  if (typeof input === "number" && Number.isNaN(input)) return "NaN";
  return typeof input;
}

function fail(path: string, message: string): never {
  throw new ValidationError(path, message);
}

function expected(kind: string, input: unknown, path: string): never {
  return fail(path, `expected ${kind}, got ${typeName(input)}`);
}

function make<T>(check: Check<T>): Schema<T> & { check: Check<T> } {
  return {
    check,
    parse: (input) => check(input, ""),
    safeParse(input) {
      try {
        return { success: true, data: check(input, "") };
      } catch (error) {
        if (error instanceof ValidationError) return { success: false, error };
        throw error;
      }
    },
  };
}

function checkOf<T>(schema: Schema<T>): Check<T> {
  if ("check" in schema && typeof schema.check === "function") {
    return schema.check as Check<T>;
  }
  return (input) => schema.parse(input);
}

function isRecord(input: unknown): input is Record<string, unknown> {
  return typeof input === "object" && input !== null && !Array.isArray(input);
}

const join = (path: string, key: string) => (path ? `${path}.${key}` : key);

export const s = {
  string: () =>
    make((input, path) =>
      typeof input === "string" ? input : expected("string", input, path),
    ),
  number: () =>
    make((input, path) =>
      typeof input === "number" && !Number.isNaN(input)
        ? input
        : expected("number", input, path),
    ),
  boolean: () =>
    make((input, path) =>
      typeof input === "boolean" ? input : expected("boolean", input, path),
    ),
  literal: <const V extends string | number | boolean | null>(value: V) =>
    make<V>((input, path) =>
      input === value ? value : fail(path, `expected ${JSON.stringify(value)}`),
    ),
  array: <T>(item: Schema<T>) => {
    const check = checkOf(item);
    return make<T[]>((input, path) => {
      if (!Array.isArray(input)) return expected("array", input, path);
      return input.map((el, i) => check(el, `${path}[${i}]`));
    });
  },
  object: <S extends Shape>(shape: S) =>
    make<ObjectOf<S>>((input, path) => {
      if (!isRecord(input)) return expected("object", input, path);
      const out: Record<string, unknown> = {};
      for (const [key, schema] of Object.entries(shape)) {
        const raw = Object.hasOwn(input, key) ? input[key] : undefined;
        const value = checkOf(schema)(raw, join(path, key));
        if (value !== undefined || !("optional" in schema)) out[key] = value;
      }
      return out as ObjectOf<S>;
    }),
  optional: <T>(inner: Schema<T>): OptionalSchema<T> => {
    const check = checkOf(inner);
    return {
      ...make<T | undefined>((input, path) =>
        input === undefined ? undefined : check(input, path),
      ),
      optional: true,
    };
  },
  union: <const M extends readonly Schema<unknown>[]>(...members: M) =>
    make<Infer<M[number]>>((input, path) => {
      for (const member of members) {
        try {
          return checkOf(member)(input, path) as Infer<M[number]>;
        } catch (error) {
          if (!(error instanceof ValidationError)) throw error;
        }
      }
      return fail(path, "no union member matched");
    }),
};
