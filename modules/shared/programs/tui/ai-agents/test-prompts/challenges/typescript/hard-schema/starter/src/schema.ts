export class ValidationError extends Error {
  path = "";
}

export type SafeResult<T> =
  | { success: true; data: T }
  | { success: false; error: ValidationError };

export interface Schema<T> {
  parse(input: unknown): T;
  safeParse(input: unknown): SafeResult<T>;
}

export const s = {};
