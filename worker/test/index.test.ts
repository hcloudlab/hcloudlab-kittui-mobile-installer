import { describe, expect, it } from "vitest";
import worker from "../src/index";

const archivePath =
  "/releases/v0.2.0-beta.2/kittui-mobile-v0.2.0-beta.2.tar.gz";
const checksumPath = `${archivePath}.sha256`;

class FakeBucket {
  readonly objects = new Map<string, Uint8Array>([
    [archivePath.slice(1), new TextEncoder().encode("archive")],
    [checksumPath.slice(1), new TextEncoder().encode("hash  archive\n")],
  ]);

  async get(key: string): Promise<R2ObjectBody | null> {
    return this.makeObject(key, true) as R2ObjectBody | null;
  }

  async head(key: string): Promise<R2Object | null> {
    return this.makeObject(key, false) as R2Object | null;
  }

  private makeObject(key: string, includeBody: boolean): object | null {
    const bytes = this.objects.get(key);
    if (bytes === undefined) {
      return null;
    }

    const metadata = {
      key,
      version: "test",
      size: bytes.byteLength,
      etag: "test-etag",
      httpEtag: '"test-etag"',
      uploaded: new Date("2026-07-25T00:00:00Z"),
      checksums: {},
      httpMetadata: {},
      customMetadata: {},
      range: undefined,
      storageClass: "Standard",
    };
    return includeBody
      ? {
          ...metadata,
          body: new ReadableStream({
            start(controller) {
              controller.enqueue(bytes);
              controller.close();
            },
          }),
          bodyUsed: false,
          arrayBuffer: async () => bytes.buffer,
          bytes: async () => bytes,
          text: async () => new TextDecoder().decode(bytes),
          json: async () => JSON.parse(new TextDecoder().decode(bytes)),
          blob: async () => new Blob([bytes]),
          writeHttpMetadata: () => undefined,
        }
      : {
          ...metadata,
          writeHttpMetadata: () => undefined,
        };
  }
}

function env(bucket = new FakeBucket()): { KML_PACKAGES: R2Bucket } {
  return { KML_PACKAGES: bucket as unknown as R2Bucket };
}

describe("download worker", () => {
  it("returns a simple health response", async () => {
    const response = await worker.fetch(
      new Request("https://example.test/healthz"),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("ok\n");
  });

  it("serves only the fixed archive with immutable download headers", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${archivePath}`),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("archive");
    expect(response.headers.get("content-type")).toBe("application/gzip");
    expect(response.headers.get("cache-control")).toBe(
      "public, max-age=31536000, immutable",
    );
    expect(response.headers.get("content-disposition")).toBe(
      'attachment; filename="kittui-mobile-v0.2.0-beta.2.tar.gz"',
    );
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
  });

  it("serves the fixed checksum as plain text", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${checksumPath}`),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("hash  archive\n");
    expect(response.headers.get("content-type")).toBe(
      "text/plain; charset=utf-8",
    );
  });

  it("returns HEAD metadata without a body", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${archivePath}`, { method: "HEAD" }),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("");
    expect(response.headers.get("content-length")).toBe("7");
    expect(response.headers.get("etag")).toBe('"test-etag"');
  });

  it("returns 404 for unknown, listing, and traversal paths", async () => {
    for (const path of [
      "/",
      "/releases/",
      "/releases/v0.2.0-beta.2/unknown.tar.gz",
      "/releases/v0.2.0-beta.2/../secret",
      "/releases/%2e%2e/secret",
    ]) {
      const response = await worker.fetch(
        new Request(`https://example.test${path}`),
        env(),
      );
      expect(response.status).toBe(404);
    }
  });

  it("returns 405 and Allow for every unsupported method", async () => {
    for (const method of ["POST", "PUT", "PATCH", "DELETE"]) {
      const response = await worker.fetch(
        new Request(`https://example.test${archivePath}`, { method }),
        env(),
      );
      expect(response.status).toBe(405);
      expect(response.headers.get("allow")).toBe("GET, HEAD");
    }
  });

  it("returns 404 when an allowlisted object is absent", async () => {
    const bucket = new FakeBucket();
    bucket.objects.delete(archivePath.slice(1));

    const response = await worker.fetch(
      new Request(`https://example.test${archivePath}`),
      env(bucket),
    );
    expect(response.status).toBe(404);
  });
});
