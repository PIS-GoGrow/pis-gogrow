import Dexie, { type EntityTable } from "dexie";
import type {
  ConsumerOrdersIndex,
  ProviderOrdersIndex,
} from "@/types";

interface CachedConsumerOrders {
  id: number;
  orders: ConsumerOrdersIndex["upcoming_orders"];
  saved_at: number;
}

interface CachedProviderOrders {
  id: number;
  upcoming_orders: ProviderOrdersIndex["upcoming_orders"];
  saved_at: number;
}

const db = new Dexie("app-offline") as Dexie & {
  consumer_orders: EntityTable<CachedConsumerOrders, "id">;
  provider_orders: EntityTable<CachedProviderOrders, "id">;
};

db.version(1).stores({
  consumer_orders: "id",
  provider_orders: "id",
});

export { db };
