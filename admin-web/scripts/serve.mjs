import { createServer } from "http";
import { readFile } from "fs/promises";
import { extname, join } from "path";
import { fileURLToPath } from "url";

const root = fileURLToPath(new URL("..", import.meta.url));
const port = Number.parseInt(process.env.PORT ?? "4173", 10);

createServer(async (request, response) => {
  const urlPath = request.url === "/" ? "/index.html" : request.url ?? "/index.html";
  const filePath = join(root, urlPath);

  try {
    const data = await readFile(filePath);
    response.writeHead(200, { "Content-Type": contentType(filePath) });
    response.end(data);
  } catch {
    response.writeHead(404, { "Content-Type": "text/plain" });
    response.end("Not found");
  }
}).listen(port, () => {
  process.stdout.write(`admin-web listening on http://127.0.0.1:${port}\n`);
});

function contentType(pathname) {
  switch (extname(pathname)) {
    case ".html":
      return "text/html; charset=utf-8";
    case ".js":
      return "text/javascript; charset=utf-8";
    case ".css":
      return "text/css; charset=utf-8";
    case ".json":
      return "application/json; charset=utf-8";
    default:
      return "application/octet-stream";
  }
}
