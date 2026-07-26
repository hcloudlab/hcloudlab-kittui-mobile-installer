import { describe, expect, it } from "vitest";
import worker from "../src/index";

const beta2ArchivePath =
  "/releases/v0.2.0-beta.2/kittui-mobile-v0.2.0-beta.2.tar.gz";
const beta2ChecksumPath = `${beta2ArchivePath}.sha256`;
const beta3ArchivePath =
  "/releases/v0.2.0-beta.3/kittui-mobile-v0.2.0-beta.3.tar.gz";
const beta3ChecksumPath = `${beta3ArchivePath}.sha256`;

class FakeBucket {
  readonly objects = new Map<string, Uint8Array>([
    [beta2ArchivePath.slice(1), new TextEncoder().encode("beta2 archive")],
    [beta2ChecksumPath.slice(1), new TextEncoder().encode("beta2 hash\n")],
    [beta3ArchivePath.slice(1), new TextEncoder().encode("beta3 archive")],
    [beta3ChecksumPath.slice(1), new TextEncoder().encode("beta3 hash\n")],
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

  it("serves the beta.3 archive with immutable download headers", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${beta3ArchivePath}`),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("beta3 archive");
    expect(response.headers.get("content-type")).toBe("application/gzip");
    expect(response.headers.get("cache-control")).toBe(
      "public, max-age=31536000, immutable",
    );
    expect(response.headers.get("content-disposition")).toBe(
      'attachment; filename="kittui-mobile-v0.2.0-beta.3.tar.gz"',
    );
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
  });

  it("serves the beta.3 checksum as plain text", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${beta3ChecksumPath}`),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("beta3 hash\n");
    expect(response.headers.get("content-type")).toBe(
      "text/plain; charset=utf-8",
    );
  });

  it("keeps the beta.2 archive available", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${beta2ArchivePath}`),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("beta2 archive");
    expect(response.headers.get("content-disposition")).toBe(
      'attachment; filename="kittui-mobile-v0.2.0-beta.2.tar.gz"',
    );
  });

  it("returns HEAD metadata without a body", async () => {
    const response = await worker.fetch(
      new Request(`https://example.test${beta3ArchivePath}`, {
        method: "HEAD",
      }),
      env(),
    );

    expect(response.status).toBe(200);
    expect(await response.text()).toBe("");
    expect(response.headers.get("content-length")).toBe("13");
    expect(response.headers.get("etag")).toBe('"test-etag"');
  });

  it("returns 404 for unknown, listing, and traversal paths", async () => {
    for (const path of [
      "/",
      "/releases/",
      "/releases/v0.2.0-beta.3/unknown.tar.gz",
      "/releases/v0.2.0-beta.3/../secret",
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
        new Request(`https://example.test${beta3ArchivePath}`, { method }),
        env(),
      );
      expect(response.status).toBe(405);
      expect(response.headers.get("allow")).toBe("GET, HEAD");
    }
  });

  it("returns 404 when an allowlisted object is absent", async () => {
    const bucket = new FakeBucket();
    bucket.objects.delete(beta3ArchivePath.slice(1));

    const response = await worker.fetch(
      new Request(`https://example.test${beta3ArchivePath}`),
      env(bucket),
    );
    expect(response.status).toBe(404);
  });
});
