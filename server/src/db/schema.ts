import { uuid, pgTable, varchar, text, timestamp } from "drizzle-orm/pg-core";
import { z } from 'zod';

const UserId = z.string().uuid().brand("UserId");
type UserId = z.infer<typeof UserId>;

export const users = pgTable("users", {
	id: uuid("id").$type<UserId>().primaryKey().defaultRandom(),
	username: text("username").notNull().unique(),
	email: text("email").notNull().unique(),
	password: text("password").notNull(),
});

const SessionId = z.string().uuid().brand("SessionId");
type SessionId = z.infer<typeof SessionId>;

export const sessions = pgTable("sessions", {
	id: uuid("id").$type<SessionId>().primaryKey().defaultRandom(),
	userId: uuid("user_id").$type<UserId>().notNull().references(() => users.id),
	expiresAt: timestamp("expires_at", { mode: "date" }).notNull(),
});