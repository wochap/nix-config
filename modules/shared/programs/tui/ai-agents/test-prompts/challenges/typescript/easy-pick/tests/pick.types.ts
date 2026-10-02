import { omit, pick } from "../src/pick.ts";

const user = { id: 1, name: "ada", admin: false };

const picked = pick(user, ["id", "name"]);
export const id: number = picked.id;
export const name: string = picked.name;
// @ts-expect-error admin was not picked
export const pickedAdmin = picked.admin;
// @ts-expect-error unknown key
export const badPick = pick(user, ["nope"]);

const rest = omit(user, ["admin"]);
export const restName: string = rest.name;
export const restId: number = rest.id;
// @ts-expect-error admin was omitted
export const restAdmin = rest.admin;
// @ts-expect-error unknown key
export const badOmit = omit(user, ["nope"]);

const keys = ["admin"] as const;
export const admin: boolean = pick(user, keys).admin;
// @ts-expect-error id is a number, not a string
export const wrong: string = pick(user, ["id"]).id;
