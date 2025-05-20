import { uuid, pgTable, varchar, text, timestamp, pgEnum, integer } from "drizzle-orm/pg-core";
import { z } from 'zod';

const UserId = z.string().uuid().brand("UserId");
export type UserId = z.infer<typeof UserId>;

export const users = pgTable("users", {
	id: uuid("id").$type<UserId>().primaryKey().defaultRandom(),
	username: text("username").notNull().unique(),
	email: text("email").notNull().unique(),
	password: text("password").notNull(),
});

const ProfileId = z.string().uuid().brand("ProfileId");
export type ProfileId = z.infer<typeof ProfileId>;

export const classes = pgEnum("class", [
	"warrior",
	"ranger",
	"berserker",
	"mutant",
	"rogue"
]);

export const profiles = pgTable("profiles", {
	id: uuid("id").$type<ProfileId>().primaryKey().defaultRandom(),
	user_id: uuid("user_id").$type<UserId>().notNull().references(() => users.id),
	class: classes("class").notNull(),
	name: text("name").notNull(),
	health: integer("health").notNull().default(100),	
});

const SessionId = z.string().uuid().brand("SessionId");
export type SessionId = z.infer<typeof SessionId>;

export const sessions = pgTable("sessions", {
	id: uuid("id").$type<SessionId>().primaryKey().defaultRandom(),
	user_id: uuid("user_id").$type<UserId>().notNull().references(() => users.id),
	expires_at: timestamp("expires_at", { mode: "date" }).notNull(),
});