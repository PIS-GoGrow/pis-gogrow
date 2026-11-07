import Dexie, { type EntityTable } from "dexie";
import type { ProviderOrdersIndex } from "@/types";

interface CachedProviderOrders {
  id: string;
  upcoming_orders: ProviderOrdersIndex["upcoming_orders"];
  saved_at: number;
}

const db = new Dexie("provider-offline") as Dexie & {
  orders: EntityTable<CachedProviderOrders, "id">;
};

db.version(1).stores({
  orders: "id",
});

export { db };
