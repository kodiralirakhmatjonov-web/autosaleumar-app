const BACKEND_URL = 'https://autosaleumar.com';

export async function GET(request: Request): Promise<Response> {
  const incoming = new URL(request.url);
  const target = new URL('/api/catalog', BACKEND_URL);
  target.search = incoming.search;

  try {
    const response = await fetch(target, {
      headers: {
        Accept: 'application/json',
        'User-Agent': 'AutoSale-Umar-App-Preview/1.0',
      },
    });

    const body = await response.arrayBuffer();
    return new Response(body, {
      status: response.status,
      headers: {
        'content-type': response.headers.get('content-type') ?? 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    });
  } catch (error) {
    console.error('Catalog preview proxy failed', error);
    return Response.json(
      { success: false, error: 'Не удалось связаться с каталогом Auto Sale Umar.' },
      { status: 502 },
    );
  }
}
