import { cp, mkdir, readFile, rm, writeFile } from "fs/promises";
import { join } from "path";
import { fileURLToPath } from "url";

const root = fileURLToPath(new URL("..", import.meta.url));
const dist = join(root, "dist");

await rm(dist, { recursive: true, force: true });
await mkdir(dist, { recursive: true });
const apiBaseUrl = process.env.ADMIN_API_BASE_URL ?? process.env.VITE_API_BASE_URL ?? "http://localhost:3000";
const indexHtml = await readFile(join(root, "index.html"), "utf8");
await writeFile(
  join(dist, "index.html"),
  indexHtml.replace("http://localhost:3000", apiBaseUrl),
  "utf8"
);
await cp(join(root, "src"), join(dist, "src"), { recursive: true });

process.stdout.write("Built admin-web/dist\n");
