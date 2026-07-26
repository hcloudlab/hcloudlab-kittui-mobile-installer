interface Env {
  KML_PACKAGES: R2Bucket;
}

interface AllowedObject {
  key: string;
  contentType: string;
  contentDisposition?: string;
}

function releaseObjects(coreVersion: string): Record<string, AllowedObject> {
  const archiveName = `kittui-mobile-${coreVersion}.tar.gz`;
  const archivePath = `/releases/${coreVersion}/${archiveName}`;
  const checksumPath = `${archivePath}.sha256`;

  return {
    [archivePath]: {
      key: archivePath.slice(1),
      contentType: "application/gzip",
      contentDisposition: `attachment; filename="${archiveName}"`,
    },
    [checksumPath]: {
      key: checksumPath.slice(1),
      contentType: "text/plain; charset=utf-8",
    },
  };
}

const ALLOWED_OBJECTS: Readonly<Record<string, AllowedObject>> = Object.freeze({
  ...releaseObjects("v0.2.0-beta.2"),
  ...releaseObjects("v0.2.0-beta.3"),
});

function baseHeaders(contentType: string): Headers {
  return new Headers({
    "Cache-Control": "public, max-age=31536000, immutable",
    "Content-Type": contentType,
    "X-Content-Type-Options": "nosniff",
  });
}

function plainResponse(status: number, body: string, method: string): Response {
  const headers = new Headers({
    "Cache-Control": "no-store",
    "Content-Type": "text/plain; charset=utf-8",
    "X-Content-Type-Options": "nosniff",
  });
  if (status === 405) {
    headers.set("Allow", "GET, HEAD");
  }
  return new Response(method === "HEAD" ? null : body, { status, headers });
}

function objectHeaders(object: R2Object, allowedObject: AllowedObject): Headers {
  const headers = baseHeaders(allowedObject.contentType);
  headers.set("Content-Length", object.size.toString());
  headers.set("ETag", object.httpEtag);
  if (allowedObject.contentDisposition !== undefined) {
    headers.set("Content-Disposition", allowedObject.contentDisposition);
  }
  return headers;
}

async function serveObject(
  request: Request,
  env: Env,
  allowedObject: AllowedObject,
): Promise<Response> {
  if (request.method === "HEAD") {
    const object = await env.KML_PACKAGES.head(allowedObject.key);
    if (object === null) {
      return plainResponse(404, "Not Found\n", request.method);
    }
    return new Response(null, {
      status: 200,
      headers: objectHeaders(object, allowedObject),
    });
  }

  const object = await env.KML_PACKAGES.get(allowedObject.key);
  if (object === null) {
    return plainResponse(404, "Not Found\n", request.method);
  }

  return new Response(object.body, {
    status: 200,
    headers: objectHeaders(object, allowedObject),
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return plainResponse(405, "Method Not Allowed\n", request.method);
    }

    const { pathname } = new URL(request.url);
    if (pathname === "/healthz") {
      return plainResponse(200, "ok\n", request.method);
    }

    const allowedObject = ALLOWED_OBJECTS[pathname];
    if (allowedObject === undefined) {
      return plainResponse(404, "Not Found\n", request.method);
    }

    return serveObject(request, env, allowedObject);
  },
};
