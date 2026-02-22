import https from 'https';

const DEFAULT_TTL_MS = 5 * 60 * 1000;

type ShopifyConfig = {
  storeDomain: string;
  storefrontToken: string;
  apiVersion: string;
};

type CacheEntry<T> = {
  data: T;
  expiresAt: number;
};

type ProductQueryParams = {
  first?: number;
  after?: string;
  query?: string;
  sortKey?: string;
  reverse?: boolean;
};

type ShopifyGraphQLResponse<T> = {
  data?: T;
  errors?: Array<{ message: string }>;
};

type ShopifyMetaobjectField = {
  key: string;
  value?: string | null;
  type?: string | null;
  reference?: {
    image?: { url: string; altText?: string };
    url?: string;
    sources?: Array<{
      url: string;
      mimeType?: string;
      format?: string;
      width?: number;
      height?: number;
    }>;
    previewImage?: { url?: string };
    id?: string;
    title?: string;
    handle?: string;
    product?: { id: string };
  } | null;
};

type ShopifyProductNode = {
  id: string;
  title: string;
  description: string;
  handle: string;
  images: { nodes: Array<{ url: string; altText?: string }> };
  priceRange: { minVariantPrice: { amount: string } };
  metafields?: Array<{ 
    key: string; 
    value: string;
    reference?: {
      image?: {
        url: string;
      };
    };
  }>;
  variants: {
    nodes: Array<{
      id: string;
      sku: string;
      title: string;
      availableForSale: boolean;
      quantityAvailable?: number;
      price: { amount: string };
      compareAtPrice?: { amount: string } | null;
      image?: { url: string; altText?: string };
      selectedOptions: Array<{ name: string; value: string }>;
    }>;
  };
  collections: { nodes: Array<{ id: string; title: string; handle: string }> };
};

export class ShopifyService {
  private config: ShopifyConfig;
  private productsCache: CacheEntry<any> | null = null;
  private collectionsCache: CacheEntry<any> | null = null;

  constructor() {
    const storeDomain = process.env.SHOPIFY_STORE_DOMAIN || '';
    const storefrontToken = process.env.SHOPIFY_STOREFRONT_TOKEN || '';
    const apiVersion = process.env.SHOPIFY_API_VERSION || '2024-10';

    if (!storeDomain || !storefrontToken) {
      throw new Error('Shopify Storefront API credentials are not configured');
    }

    this.config = { storeDomain, storefrontToken, apiVersion };
  }

  public async getProducts(params: ProductQueryParams = {}) {
    const { first = 20, after, query, sortKey, reverse } = params;
    const shouldUseCache = !after && !query && !sortKey && !reverse;

    if (shouldUseCache && this.productsCache && this.productsCache.expiresAt > Date.now()) {
      return this.productsCache.data;
    }

    const queryText = `
      query Products($first: Int!, $after: String, $query: String, $sortKey: ProductSortKeys, $reverse: Boolean) {
        products(first: $first, after: $after, query: $query, sortKey: $sortKey, reverse: $reverse) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            title
            description
            handle
            images(first: 10) { 
              nodes { 
                url 
                altText
              } 
            }
            priceRange { minVariantPrice { amount } }
            metafields(identifiers: [
              {namespace: "custom", key: "01_foto"},
              {namespace: "custom", key: "02_foto"},
              {namespace: "custom", key: "03_foto"},
              {namespace: "custom", key: "tabelamedida"},
              {namespace: "custom", key: "bulletsMobile"}
            ]) {
              key
              value
              reference {
                ... on MediaImage {
                  image {
                    url
                  }
                }
                ... on GenericFile {
                  url
                }
              }
            }
            variants(first: 100) {
              nodes {
                id
                sku
                title
                availableForSale
                quantityAvailable
                price { amount }
                compareAtPrice { amount }
                image { url altText }
                selectedOptions { name value }
              }
            }
            collections(first: 1) { nodes { id title handle } }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      products: { pageInfo: { hasNextPage: boolean; endCursor: string | null }; nodes: ShopifyProductNode[] };
    }>(queryText, { first, after, query, sortKey, reverse });

    const payload = {
      products: response.products.nodes.map((product) => this.mapProduct(product)),
      pageInfo: response.products.pageInfo,
    };

    if (shouldUseCache) {
      this.productsCache = {
        data: payload,
        expiresAt: Date.now() + DEFAULT_TTL_MS,
      };
    }

    return payload;
  }

  public async getProductById(productId: string) {
    const gid = productId.startsWith('gid://shopify/Product/')
      ? productId
      : `gid://shopify/Product/${productId}`;

    const queryText = `
      query Product($id: ID!) {
        product(id: $id) {
          id
          title
          description
          handle
          images(first: 10) { 
            nodes { 
              url 
              altText
            } 
          }
          priceRange { minVariantPrice { amount } }
          metafields(identifiers: [
            {namespace: "custom", key: "01_foto"},
            {namespace: "custom", key: "02_foto"},
            {namespace: "custom", key: "03_foto"},
            {namespace: "custom", key: "bulletsMobile"}
          ]) {
            key
            value
            reference {
              ... on MediaImage {
                image {
                  url
                }
              }
            }
          }
          variants(first: 100) {
            nodes {
              id
              sku
              title
              availableForSale
              quantityAvailable
              price { amount }
              compareAtPrice { amount }
              image { url altText }
              selectedOptions { name value }
            }
          }
          collections(first: 5) { nodes { id title handle } }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      product: ShopifyProductNode | null;
    }>(queryText, { id: gid });

    if (!response.product) {
      throw new Error('Product not found');
    }

    return this.mapProduct(response.product);
  }

  public async getCollections() {
    if (this.collectionsCache && this.collectionsCache.expiresAt > Date.now()) {
      return this.collectionsCache.data;
    }

    const queryText = `
      query Collections($first: Int!) {
        collections(first: $first) {
          nodes { id title handle }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      collections: { nodes: Array<{ id: string; title: string; handle: string }> };
    }>(queryText, { first: 50 });

    const payload = {
      collections: response.collections.nodes.map((collection) => ({
        id: this.parseShopifyId(collection.id),
        name: collection.title,
        slug: collection.handle,
      })),
    };

    this.collectionsCache = {
      data: payload,
      expiresAt: Date.now() + DEFAULT_TTL_MS,
    };

    return payload;
  }

  public async getStoriesCollections() {
    const queryText = `
      query StoriesCollections($first: Int!) {
        collections(first: $first) {
          nodes {
            id
            title
            handle
            image {
              url
              altText
            }
            metafields(identifiers: [{namespace: "custom", key: "stories"}]) {
              key
              value
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      collections: { 
        nodes: Array<{ 
          id: string; 
          title: string; 
          handle: string;
          image?: { url: string; altText?: string };
          metafields: Array<{ key: string; value: string }>;
        }> 
      };
    }>(queryText, { first: 50 });

    const storiesCollections = response.collections.nodes
      .filter((collection) => {
        const metafields = collection.metafields || [];
        const storiesMetafield = metafields.find((mf) => mf && mf.key === 'stories');
        return storiesMetafield && storiesMetafield.value && storiesMetafield.value.toLowerCase() === 'sim';
      })
      .map((collection) => ({
        id: this.parseShopifyId(collection.id),
        gid: collection.id,
        name: collection.title,
        slug: collection.handle,
        image: collection.image?.url || null,
      }));

    return { collections: storiesCollections };
  }

  public async getProductsByCollection(collectionGid: string, params: ProductQueryParams = {}) {
    const { first = 20, after, sortKey, reverse } = params;

    const queryText = `
      query CollectionProducts($collectionId: ID!, $first: Int!, $after: String, $sortKey: ProductCollectionSortKeys, $reverse: Boolean) {
        collection(id: $collectionId) {
          products(first: $first, after: $after, sortKey: $sortKey, reverse: $reverse) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              title
              description
              handle
              images(first: 10) { 
                nodes { 
                  url 
                  altText
                } 
              }
              priceRange { minVariantPrice { amount } }
              metafields(identifiers: [
                {namespace: "custom", key: "01_foto"},
                {namespace: "custom", key: "02_foto"},
                {namespace: "custom", key: "03_foto"},
                {namespace: "custom", key: "tabelamedida"},
                {namespace: "custom", key: "bulletsMobile"}
              ]) {
                key
                value
                reference {
                  ... on MediaImage {
                    image {
                      url
                    }
                  }
                  ... on GenericFile {
                    url
                  }
                  ... on GenericFile {
                    url
                  }
                }
              }
              variants(first: 100) {
                nodes {
                  id
                  sku
                  title
                  availableForSale
                  quantityAvailable
                  price { amount }
                  compareAtPrice { amount }
                  image { url altText }
                  selectedOptions { name value }
                }
              }
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      collection: {
        products: { pageInfo: { hasNextPage: boolean; endCursor: string | null }; nodes: Omit<ShopifyProductNode, 'collections'>[] };
      } | null;
    }>(queryText, { collectionId: collectionGid, first, after, sortKey, reverse });

    if (!response.collection) {
      return { products: [], pageInfo: { hasNextPage: false, endCursor: null } };
    }

    const payload = {
      products: response.collection.products.nodes.map((product) => this.mapProductWithoutCollections(product)),
      pageInfo: response.collection.products.pageInfo,
    };

    return payload;
  }

  public async createCheckout(lines: Array<{ merchandiseId: string; quantity: number }>) {
    const mutationText = `
      mutation CartCreate($lines: [CartLineInput!]!) {
        cartCreate(input: { lines: $lines }) {
          cart { checkoutUrl }
          userErrors { field message }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      cartCreate: { cart: { checkoutUrl: string } | null; userErrors: Array<{ field: string[]; message: string }> };
    }>(mutationText, { lines });

    if (response.cartCreate.userErrors.length > 0) {
      throw new Error(response.cartCreate.userErrors[0].message);
    }

    if (!response.cartCreate.cart?.checkoutUrl) {
      throw new Error('Checkout URL not generated');
    }

    return { checkoutUrl: response.cartCreate.cart.checkoutUrl };
  }

  public clearCache() {
    this.productsCache = null;
    this.collectionsCache = null;
  }

  private async graphqlRequest<T>(query: string, variables: Record<string, unknown>): Promise<T> {
    const { storeDomain, storefrontToken, apiVersion } = this.config;
    const postData = JSON.stringify({ query, variables });

    const options = {
      method: 'POST',
      hostname: storeDomain,
      path: `/api/${apiVersion}/graphql.json`,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'X-Shopify-Storefront-Access-Token': storefrontToken,
      },
    };

    const result = await new Promise<string>((resolve, reject) => {
      const request = https.request(options, (response) => {
        let data = '';
        response.on('data', (chunk) => {
          data += chunk;
        });
        response.on('end', () => resolve(data));
      });

      request.on('error', (error) => reject(error));
      request.write(postData);
      request.end();
    });

    const parsed: ShopifyGraphQLResponse<T> = JSON.parse(result);
    if (parsed.errors && parsed.errors.length > 0) {
      throw new Error(parsed.errors[0].message);
    }

    if (!parsed.data) {
      throw new Error('Empty Shopify response');
    }

    return parsed.data;
  }

  private getMetafieldImageUrl(metafields: Array<{ key: string; value: string; reference?: { image?: { url: string } } }> | undefined, key: string): string | null {
    const metafield = metafields?.find(mf => mf && mf.key === key);
    if (!metafield) return null;
    
    // Se tem reference com image.url, usa isso (para file_reference metafields)
    if (metafield.reference?.image?.url) {
      return metafield.reference.image.url;
    }
    
    // Se o value já é uma URL válida, usa direto
    if (metafield.value && (metafield.value.startsWith('http://') || metafield.value.startsWith('https://'))) {
      return metafield.value;
    }
    
    return null;
  }

  private getMetafieldValue(metafields: Array<{ key: string; value?: string | null; reference?: { url?: string; image?: { url?: string } } }> | undefined, key: string): string | null {
    const metafield = metafields?.find(mf => mf && mf.key === key);
    if (!metafield) return null;
    
    // Debug: log completo do metafield para tabelamedida
    if (key === 'tabelamedida') {
      console.log(`[DEBUG] Metafield ${key}:`, JSON.stringify(metafield, null, 2));
    }
    
    // Primeiro tenta pegar de reference.url (para file_reference)
    if (metafield.reference?.url) {
      return metafield.reference.url;
    }
    
    // Depois tenta de reference.image.url (para MediaImage)
    if (metafield.reference?.image?.url) {
      return metafield.reference.image.url;
    }
    
    // Por fim, tenta o value direto
    const value = metafield.value;
    if (!value) {
      if (key === 'tabelamedida') console.log(`[DEBUG] ${key} - value is null/empty`);
      return null;
    }
    
    // Remove espaços em branco e retorna se houver conteúdo
    const trimmed = value.trim();
    const result = trimmed.length > 0 ? trimmed : null;
    
    if (key === 'tabelamedida') {
      console.log(`[DEBUG] ${key} - final result:`, result);
    }
    
    return result;
  }

  private mapProductWithoutCollections(product: Omit<ShopifyProductNode, 'collections'>) {
    const productId = this.parseShopifyId(product.id);

    const compareAtPrices = product.variants.nodes
      .map((variant) => variant.compareAtPrice?.amount)
      .filter((value): value is string => Boolean(value))
      .map((value) => parseFloat(value));

    const compareAtPrice = compareAtPrices.length > 0
      ? Math.max(...compareAtPrices)
      : null;

    // Se o preço mínimo for zero, busca o primeiro preço não-zero das variantes
    let productPrice = parseFloat(product.priceRange.minVariantPrice.amount);
    if (productPrice === 0) {
      const nonZeroPrices = product.variants.nodes
        .map((v) => parseFloat(v.price.amount))
        .filter((p) => p > 0);
      productPrice = nonZeroPrices.length > 0 ? Math.min(...nonZeroPrices) : 0;
    }

    return {
      id: productId,
      title: product.title,
      description: product.description,
      price: productPrice,
      compareAtPrice,
      sku: product.variants.nodes[0]?.sku || product.handle,
      categoryId: null,
      images: product.images.nodes.map((image) => ({ url: image.url, altText: image.altText || null })),
      metafield01Foto: this.getMetafieldImageUrl(product.metafields, '01_foto'),
      metafield02Foto: this.getMetafieldImageUrl(product.metafields, '02_foto'),
      metafield03Foto: this.getMetafieldImageUrl(product.metafields, '03_foto'),
      tabelaMedida: this.getMetafieldValue(product.metafields, 'tabelamedida'),
      bulletPoints: product.metafields?.find(mf => mf && mf.key === 'bulletsMobile')?.value || null,
      variants: product.variants.nodes.map((variant) => {
        const sizeOption = variant.selectedOptions.find(
          (option) => option.name.toLowerCase() === 'size' || option.name.toLowerCase() === 'tamanho'
        );
        const colorOption = variant.selectedOptions.find(
          (option) => option.name.toLowerCase() === 'color' || option.name.toLowerCase() === 'cor'
        );

        return {
          id: this.parseShopifyId(variant.id),
          productId,
          sku: variant.sku || variant.title,
          size: sizeOption?.value || null,
          color: colorOption?.value || null,
          stock: variant.quantityAvailable ?? 0,
          price: parseFloat(variant.price.amount),
          compareAtPrice: variant.compareAtPrice?.amount
            ? parseFloat(variant.compareAtPrice.amount)
            : null,
          image: variant.image?.url || null,
          available: variant.availableForSale,
        };
      }),
    };
  }

  private mapProduct(product: ShopifyProductNode) {
    const productId = this.parseShopifyId(product.id);
    const collection = product.collections.nodes[0];
    const category = collection
      ? {
          id: this.parseShopifyId(collection.id),
          name: collection.title,
          slug: collection.handle,
        }
      : null;

    const compareAtPrices = product.variants.nodes
      .map((variant) => variant.compareAtPrice?.amount)
      .filter((value): value is string => Boolean(value))
      .map((value) => parseFloat(value));

    const compareAtPrice = compareAtPrices.length > 0
      ? Math.max(...compareAtPrices)
      : null;

    // Se o preço mínimo for zero, busca o primeiro preço não-zero das variantes
    let productPrice = parseFloat(product.priceRange.minVariantPrice.amount);
    if (productPrice === 0) {
      const nonZeroPrices = product.variants.nodes
        .map((v) => parseFloat(v.price.amount))
        .filter((p) => p > 0);
      productPrice = nonZeroPrices.length > 0 ? Math.min(...nonZeroPrices) : 0;
    }

    return {
      id: productId,
      title: product.title,
      description: product.description,
      price: productPrice,
      compareAtPrice,
      sku: product.variants.nodes[0]?.sku || product.handle,
      categoryId: category?.id || null,
      images: product.images.nodes.map((image) => ({ url: image.url, altText: image.altText || null })),
      metafield01Foto: this.getMetafieldImageUrl(product.metafields, '01_foto'),
      metafield02Foto: this.getMetafieldImageUrl(product.metafields, '02_foto'),
      metafield03Foto: this.getMetafieldImageUrl(product.metafields, '03_foto'),
      tabelaMedida: this.getMetafieldValue(product.metafields, 'tabelamedida'),
      bulletPoints: product.metafields?.find(mf => mf && mf.key === 'bulletsMobile')?.value || null,
      variants: product.variants.nodes.map((variant) => {
        const sizeOption = variant.selectedOptions.find(
          (option) => option.name.toLowerCase() === 'size' || option.name.toLowerCase() === 'tamanho'
        );
        const colorOption = variant.selectedOptions.find(
          (option) => option.name.toLowerCase() === 'color' || option.name.toLowerCase() === 'cor'
        );

        return {
          id: this.parseShopifyId(variant.id),
          productId,
          sku: variant.sku || variant.title,
          size: sizeOption?.value || null,
          color: colorOption?.value || null,
          stock: variant.quantityAvailable ?? 0,
          price: parseFloat(variant.price.amount),
          compareAtPrice: variant.compareAtPrice?.amount
            ? parseFloat(variant.compareAtPrice.amount)
            : null,
          image: variant.image?.url || null,
          available: variant.availableForSale,
        };
      }),
      category,
    };
  }

  public async getShopMetafields() {
    const queryText = `
      query ShopMetafields {
        shop {
          metafields(identifiers: [
            {namespace: "custom", key: "bannerHomeMobile"}
          ]) {
            key
            value
            type
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      shop: {
        metafields: Array<{ key: string; value: string; type: string }>;
      };
    }>(queryText, {});

    if (!response.shop || !response.shop.metafields) {
      return {
        bannerHomeMobile: null,
      };
    }

    const bannerMetafield = response.shop.metafields.find((mf: { key: string; value: string; type: string } | null) => mf && mf.key === 'bannerHomeMobile');
    
    return {
      bannerHomeMobile: bannerMetafield?.value || null,
    };
  }

  public async getProductReviews(productGid?: string) {
    const metaobjectType = process.env.SHOPIFY_REVIEWS_METAOBJECT_TYPE || 'avaliacoesproduto';

    const queryText = `
      query ProductReviews($type: String!, $first: Int!) {
        metaobjects(type: $type, first: $first) {
          nodes {
            id
            handle
            type
            fields {
              key
              value
              type
              reference {
                ... on Product {
                  id
                  title
                  handle
                }
                ... on MediaImage {
                  image {
                    url
                    altText
                  }
                }
                ... on GenericFile {
                  url
                }
              }
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      metaobjects: {
        nodes: Array<{
          id: string;
          handle: string;
          type: string;
          fields: ShopifyMetaobjectField[];
        }>;
      };
    }>(queryText, { type: metaobjectType, first: 100 });

    const nodes = response.metaobjects?.nodes || [];

    const reviews = nodes.map((node) => {
      const fields = node.fields || [];

      const productRef = this.readReference(fields, ['produto', 'product']);
      const starsRaw = this.readFieldValue(fields, ['estrelas', 'stars', 'rating']);
      const stars = starsRaw ? parseInt(starsRaw, 10) : null;
      const date = this.readFieldValue(fields, ['data', 'date']) || null;
      const photoUrl =
        this.readReferenceImage(fields, ['foto', 'photo', 'image', 'imagem']) ||
        this.readFieldValue(fields, ['foto', 'photo', 'image_url']) ||
        null;
      const author = this.readFieldValue(fields, ['nome', 'autor', 'author', 'name']) || null;
      const comment = this.readRichTextPlain(fields, ['avaliacao', 'comentario', 'comment', 'texto', 'text', 'review'])
        || this.readFieldValue(fields, ['avaliacao', 'comentario', 'comment', 'texto', 'text', 'review'])
        || null;
      const title = this.readFieldValue(fields, ['titulo', 'title']) || null;

      return {
        id: node.id,
        handle: node.handle,
        author,
        title,
        comment,
        stars,
        date,
        photoUrl,
        productId: productRef?.id ? this.parseShopifyId(productRef.id) : null,
        productGid: productRef?.id || null,
        productTitle: productRef?.title || null,
        productHandle: productRef?.handle || null,
      };
    });

    // If a specific product GID was requested, filter reviews for that product
    const filtered = productGid
      ? reviews.filter((r) => r.productGid === productGid)
      : reviews;

    return {
      sourceMetaobjectType: metaobjectType,
      total: filtered.length,
      reviews: filtered,
    };
  }

  public async getClips(referenceMetafieldId?: string, metaobjectType?: string) {
    const rawMetafieldId =
      referenceMetafieldId ||
      process.env.SHOPIFY_CLIPS_REFERENCE_LIST_ID ||
      '186305708310';

    const clipsMetaobjectType =
      metaobjectType ||
      process.env.SHOPIFY_CLIPS_METAOBJECT_TYPE ||
      'lista_de_referencias';

    const metafieldGid = rawMetafieldId.startsWith('gid://')
      ? rawMetafieldId
      : `gid://shopify/Metafield/${rawMetafieldId}`;

    const queryText = `
      query ClipsByMetafield($id: ID!, $first: Int!) {
        node(id: $id) {
          ... on Metafield {
            id
            references(first: $first) {
              nodes {
                ... on Metaobject {
                  id
                  handle
                  type
                  fields {
                    key
                    value
                    type
                    reference {
                      ... on Product {
                        id
                        title
                        handle
                      }
                      ... on Collection {
                        id
                        title
                        handle
                      }
                      ... on ProductVariant {
                        id
                        product {
                          id
                        }
                      }
                      ... on MediaImage {
                        image {
                          url
                          altText
                        }
                      }
                      ... on GenericFile {
                        url
                      }
                      ... on Video {
                        sources {
                          url
                          mimeType
                          format
                          width
                          height
                        }
                        previewImage {
                          url
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      node: {
        id: string;
        references?: {
          nodes: Array<{
            id: string;
            handle: string;
            type: string;
            fields: ShopifyMetaobjectField[];
          }>;
        };
      } | null;
    }>(queryText, { id: metafieldGid, first: 100 });

    let nodes = response.node?.references?.nodes || [];

    if (nodes.length === 0) {
      nodes = await this.getClipMetaobjectsByType(clipsMetaobjectType);
    }
    const now = new Date();

    let clips = nodes
      .map((node) => {
        const fields = node.fields || [];

        const title = this.readFieldValue(fields, ['title', 'nome', 'name']) || node.handle;
        const subtitle = this.readFieldValue(fields, ['subtitle', 'subtitulo', 'description', 'descricao']) || null;
        const videoUrl = this.normalizeClipMediaValue(
          this.readReferenceVideoUrl(fields, ['video_url', 'video', 'video_file']) ||
          this.readFieldValue(fields, [
            'video_url',
            'video',
            'videoUrl',
            'url',
            'video_link',
            'video_mp4',
            'url_video',
          ])
        );
        const thumbUrl = this.normalizeClipMediaValue(
          this.readReferenceImage(fields, ['thumb', 'thumbnail', 'cover', 'preview', 'thumb_url', 'preview_image']) ||
          this.readFieldValue(fields, ['thumb_url', 'thumbnail', 'cover', 'preview_image'])
        );

        const ctaLabel = this.readFieldValue(fields, ['cta_label', 'ctaLabel', 'button_label']) || 'Confira agora';
        const ctaTypeRaw = this.readFieldValue(fields, ['cta_type', 'ctaType']) || '';
        const ctaTarget = this.readFieldValue(fields, ['cta_target', 'ctaTarget', 'url']) || null;

        const productRef = this.readReference(fields, ['product', 'produto']);
        const variantRef = this.readReference(fields, ['variant', 'variante', 'product_variant', 'cta_target']);
        const collectionRef = this.readReference(fields, ['collection', 'colecao']);

        let ctaType = ctaTypeRaw.toLowerCase();
        const productIdFromTarget = this.parsePotentialProductId(ctaTarget);
        if (!ctaType) {
          if (productRef?.id || variantRef?.product?.id || productIdFromTarget) ctaType = 'product';
          else if (collectionRef?.id) ctaType = 'collection';
          else if (ctaTarget) ctaType = 'url';
          else ctaType = 'none';
        }

        if (ctaType === 'url' && (variantRef?.product?.id || ctaTarget?.includes('gid://shopify/ProductVariant/'))) {
          ctaType = 'product';
        }

        const sortOrder = this.toNumber(this.readFieldValue(fields, ['order', 'sort_order', 'position'])) ?? 9999;
        const likes = this.toNumber(this.readFieldValue(fields, ['likes', 'like_count'])) ?? 0;

        const isActiveRaw = this.readFieldValue(fields, ['is_active', 'active', 'enabled', 'status']);
        const isActive = isActiveRaw == null ? true : this.toBoolean(isActiveRaw);

        const startAtRaw = this.readFieldValue(fields, ['start_at', 'startAt', 'published_at']);
        const endAtRaw = this.readFieldValue(fields, ['end_at', 'endAt', 'expires_at']);
        const startAt = startAtRaw ? new Date(startAtRaw) : null;
        const endAt = endAtRaw ? new Date(endAtRaw) : null;

        const inWindow =
          (!startAt || (!Number.isNaN(startAt.getTime()) && startAt <= now)) &&
          (!endAt || (!Number.isNaN(endAt.getTime()) && endAt >= now));

        return {
          id: node.id,
          handle: node.handle,
          title,
          subtitle,
          videoUrl,
          thumbUrl,
          likes,
          isActive,
          sortOrder,
          ctaLabel,
          ctaType,
          ctaTarget,
          productId: productRef?.id
            ? this.parseShopifyId(productRef.id)
            : variantRef?.product?.id
            ? this.parseShopifyId(variantRef.product.id)
            : productIdFromTarget,
          productGid: productRef?.id || variantRef?.product?.id || this.parsePotentialProductGid(ctaTarget),
          productVariantGid: variantRef?.id || this.parsePotentialVariantGid(ctaTarget),
          collectionGid: collectionRef?.id || null,
          color: this.readFieldValue(fields, ['color', 'cor', 'product_color']) || null,
          variantLabel:
            this.readFieldValue(fields, ['variant', 'variante', 'variant_label']) ||
            this.readFieldValue(fields, ['color', 'cor', 'product_color']) ||
            null,
          startAt: startAt && !Number.isNaN(startAt.getTime()) ? startAt.toISOString() : null,
          endAt: endAt && !Number.isNaN(endAt.getTime()) ? endAt.toISOString() : null,
          inWindow,
        };
      })
      .filter((clip) => clip.videoUrl && clip.isActive && clip.inWindow)
      .sort((a, b) => a.sortOrder - b.sortOrder);

    clips = await this.resolveClipMediaGids(clips);
    clips = await this.enrichClipsFromVariantGids(clips);
    clips = await this.enrichClipsWithProductPrice(clips);

    return {
      sourceMetafieldId: rawMetafieldId,
      sourceMetafieldGid: metafieldGid,
      sourceMetaobjectType: clipsMetaobjectType,
      total: clips.length,
      clips,
    };
  }

  private async getClipMetaobjectsByType(type: string) {
    const queryText = `
      query ClipsByType($type: String!, $first: Int!) {
        metaobjects(type: $type, first: $first) {
          nodes {
            id
            handle
            type
            fields {
              key
              value
              type
              reference {
                ... on Product {
                  id
                  title
                  handle
                }
                ... on Collection {
                  id
                  title
                  handle
                }
                ... on ProductVariant {
                  id
                  product {
                    id
                  }
                }
                ... on MediaImage {
                  image {
                    url
                    altText
                  }
                }
                ... on GenericFile {
                  url
                }
                ... on Video {
                  sources {
                    url
                    mimeType
                    format
                    width
                    height
                  }
                  previewImage {
                    url
                  }
                }
              }
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{
      metaobjects: {
        nodes: Array<{
          id: string;
          handle: string;
          type: string;
          fields: ShopifyMetaobjectField[];
        }>;
      };
    }>(queryText, { type, first: 100 });

    return response.metaobjects?.nodes || [];
  }

  /** Extract plain text from a Shopify rich_text_field JSON value */
  private readRichTextPlain(fields: ShopifyMetaobjectField[], keys: string[]): string | null {
    const normalizedKeys = keys.map((k) => k.toLowerCase());
    const found = fields.find(
      (field) => field && normalizedKeys.includes((field.key || '').toLowerCase())
    );
    const rawValue = found?.value?.trim();
    if (!rawValue) return null;

    try {
      const parsed = JSON.parse(rawValue);
      const texts: string[] = [];
      const walk = (node: any) => {
        if (!node) return;
        if (node.type === 'text' && typeof node.value === 'string') {
          texts.push(node.value.trim());
        }
        if (Array.isArray(node.children)) {
          node.children.forEach(walk);
        }
      };
      walk(parsed);
      const result = texts.join(' ').trim();
      return result || null;
    } catch {
      return null;
    }
  }

  private readFieldValue(fields: ShopifyMetaobjectField[], keys: string[]): string | null {
    const normalizedKeys = keys.map((k) => k.toLowerCase());
    const found = fields.find(
      (field) => field && normalizedKeys.includes((field.key || '').toLowerCase())
    );
    const rawValue = found?.value?.trim();
    if (!rawValue) return null;

    if (rawValue.startsWith('{') && rawValue.endsWith('}')) {
      try {
        const parsed = JSON.parse(rawValue) as { url?: string };
        if (parsed.url && parsed.url.trim()) {
          return parsed.url.trim();
        }
      } catch {
        // Ignore malformed JSON and fallback to raw value
      }
    }

    return rawValue;
  }

  private readReference(fields: ShopifyMetaobjectField[], keys: string[]) {
    const normalizedKeys = keys.map((k) => k.toLowerCase());
    const found = fields.find(
      (field) => field && normalizedKeys.includes((field.key || '').toLowerCase())
    );
    return found?.reference || null;
  }

  private readReferenceImage(fields: ShopifyMetaobjectField[], keys: string[]): string | null {
    const reference = this.readReference(fields, keys);
    const imageUrl = reference?.image?.url?.trim();
    if (imageUrl) return imageUrl;

    const previewUrl = reference?.previewImage?.url?.trim();
    if (previewUrl) return previewUrl;

    const directUrl = reference?.url?.trim();
    if (directUrl) return directUrl;

    return null;
  }

  private readReferenceVideoUrl(fields: ShopifyMetaobjectField[], keys: string[]): string | null {
    const reference = this.readReference(fields, keys);
    const sourceUrl = this.choosePreferredVideoSource(reference?.sources || []);
    if (sourceUrl) return sourceUrl;

    const genericUrl = reference?.url?.trim();
    if (genericUrl) return genericUrl;

    return null;
  }

  private normalizeClipMediaValue(value: string | null): string | null {
    if (!value) return null;

    const normalized = this.extractMediaValue(value, 0);
    return normalized || null;
  }

  private extractMediaValue(input: unknown, depth: number): string | null {
    if (input == null || depth > 4) return null;

    if (typeof input === 'string') {
      const raw = input.trim();
      if (!raw) return null;

      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }

      const gidInText = this.extractShopifyMediaGid(raw);
      if (gidInText) return gidInText;

      if ((raw.startsWith('{') && raw.endsWith('}')) || (raw.startsWith('[') && raw.endsWith(']'))) {
        try {
          const parsed = JSON.parse(raw);
          return this.extractMediaValue(parsed, depth + 1);
        } catch {
          return raw;
        }
      }

      return raw;
    }

    if (Array.isArray(input)) {
      for (const item of input) {
        const candidate = this.extractMediaValue(item, depth + 1);
        if (candidate) return candidate;
      }
      return null;
    }

    if (typeof input === 'object') {
      const obj = input as Record<string, unknown>;
      const preferredKeys = [
        'url',
        'src',
        'originalSrc',
        'id',
        'gid',
        'value',
        'video',
        'file',
        'media',
        'reference',
      ];

      for (const key of preferredKeys) {
        if (!(key in obj)) continue;
        const candidate = this.extractMediaValue(obj[key], depth + 1);
        if (candidate) return candidate;
      }

      for (const key of Object.keys(obj)) {
        const candidate = this.extractMediaValue(obj[key], depth + 1);
        if (candidate) return candidate;
      }
    }

    return null;
  }

  private choosePreferredVideoSource(
    sources: Array<{
      url?: string;
      mimeType?: string;
      format?: string;
      width?: number;
      height?: number;
    }>
  ): string | null {
    if (!Array.isArray(sources) || sources.length === 0) return null;

    const candidates = sources
      .map((source) => {
        const url = String(source?.url || '').trim();
        if (!url) return null;

        const lowerUrl = url.toLowerCase();
        const mimeType = String(source?.mimeType || '').toLowerCase();
        const format = String(source?.format || '').toLowerCase();
        const isMp4 =
          lowerUrl.includes('.mp4') ||
          mimeType.includes('mp4') ||
          format === 'mp4';
        const isHls =
          lowerUrl.includes('.m3u8') ||
          mimeType.includes('mpegurl') ||
          format === 'm3u8' ||
          format === 'hls';

        const height = Number(source?.height || 0);
        const width = Number(source?.width || 0);
        const resolution = Number.isFinite(height) && height > 0
          ? height
          : Number.isFinite(width) && width > 0
          ? width
          : 1080;

        const bitrateMatch = /([0-9]+(?:\.[0-9]+)?)mbps/i.exec(url);
        const bitrate = bitrateMatch ? Number(bitrateMatch[1]) : 99;

        let score = 0;
        if (isMp4) score += 1000;
        if (isHls) score -= 200;
        score -= Math.max(0, resolution - 720);
        score -= Math.round(bitrate * 10);

        return { url, score };
      })
      .filter((item): item is { url: string; score: number } => item !== null)
      .sort((a, b) => b.score - a.score);

    return candidates[0]?.url || null;
  }

  private extractShopifyMediaGid(value: string): string | null {
    const match = /gid:\/\/shopify\/(Video|MediaImage|GenericFile)\/\d+/.exec(value);
    return match ? match[0] : null;
  }

  private async resolveClipMediaGids<T extends { videoUrl: any; thumbUrl: any }>(clips: T[]): Promise<T[]> {
    const mediaGids = new Set<string>();

    for (const clip of clips) {
      const videoUrl = this.normalizeClipMediaValue(String(clip.videoUrl || ''));
      const thumbUrl = this.normalizeClipMediaValue(String(clip.thumbUrl || ''));
      const videoGid = videoUrl ? this.extractShopifyMediaGid(videoUrl) : null;
      const thumbGid = thumbUrl ? this.extractShopifyMediaGid(thumbUrl) : null;
      if (videoGid) mediaGids.add(videoGid);
      if (thumbGid) mediaGids.add(thumbGid);
    }

    if (mediaGids.size === 0) {
      return clips;
    }

    const queryText = `
      query ResolveMedia($ids: [ID!]!) {
        nodes(ids: $ids) {
          ... on Video {
            id
            sources {
              url
              mimeType
              format
              width
              height
            }
            previewImage {
              url
            }
          }
          ... on MediaImage {
            id
            image {
              url
            }
          }
          ... on GenericFile {
            id
            url
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{ nodes: Array<any> }>(queryText, {
      ids: Array.from(mediaGids),
    });

    const byId = new Map<string, string>();
    for (const node of response.nodes || []) {
      if (!node?.id) continue;
      const resolved =
        this.choosePreferredVideoSource(node.sources || []) ||
        node.image?.url ||
        node.previewImage?.url ||
        node.url ||
        null;
      if (resolved) {
        byId.set(String(node.id), String(resolved));
      }
    }

    return clips.map((clip) => {
      const rawVideo = this.normalizeClipMediaValue(String(clip.videoUrl || '')) || clip.videoUrl;
      const rawThumb = this.normalizeClipMediaValue(String(clip.thumbUrl || '')) || clip.thumbUrl;

      const videoGid = this.extractShopifyMediaGid(String(rawVideo || ''));
      const thumbGid = this.extractShopifyMediaGid(String(rawThumb || ''));

      return {
        ...clip,
        videoUrl: (videoGid ? byId.get(videoGid) : null) || rawVideo,
        thumbUrl: (thumbGid ? byId.get(thumbGid) : null) || rawThumb,
      } as T;
    });
  }

  private async enrichClipsFromVariantGids<
    T extends {
      variantLabel?: string | null;
      color?: string | null;
      productId?: number | null;
      productGid?: string | null;
      productVariantGid?: string | null;
      price?: number | null;
      originalPrice?: number | null;
      thumbUrl?: string | null;
    }
  >(clips: T[]): Promise<T[]> {
    const variantGids = Array.from(
      new Set(
        clips
          .map((clip) => String(clip.productVariantGid || ''))
          .filter((gid) => gid.startsWith('gid://shopify/ProductVariant/'))
      )
    );

    if (variantGids.length === 0) {
      return clips;
    }

    const queryText = `
      query ResolveVariants($ids: [ID!]!) {
        nodes(ids: $ids) {
          ... on ProductVariant {
            id
            title
            price {
              amount
            }
            compareAtPrice {
              amount
            }
            image {
              url
              altText
            }
            selectedOptions {
              name
              value
            }
            product {
              id
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{ nodes: Array<any> }>(queryText, {
      ids: variantGids,
    });

    const variantMap = new Map<
      string,
      {
        title: string | null;
        color: string | null;
        productGid: string | null;
        productId: number | null;
        price: number | null;
        originalPrice: number | null;
        thumbUrl: string | null;
      }
    >();

    for (const node of response.nodes || []) {
      if (!node?.id) continue;
      const selectedOptions = Array.isArray(node.selectedOptions) ? node.selectedOptions : [];
      const colorOption = selectedOptions.find((opt: any) => {
        const name = String(opt?.name || '').trim().toLowerCase();
        return name === 'color' || name === 'cor';
      });

      const productGid = node.product?.id ? String(node.product.id) : null;
      const price = node.price?.amount ? parseFloat(node.price.amount) : null;
      const originalPrice = node.compareAtPrice?.amount ? parseFloat(node.compareAtPrice.amount) : null;
      const thumbUrl = node.image?.url ? String(node.image.url) : null;

      variantMap.set(String(node.id), {
        title: node.title ? String(node.title) : null,
        color: colorOption?.value ? String(colorOption.value) : null,
        productGid,
        productId: productGid ? this.parseShopifyId(productGid) : null,
        price,
        originalPrice,
        thumbUrl,
      });
    }

    return clips.map((clip) => {
      const gid = String(clip.productVariantGid || '');
      const resolved = variantMap.get(gid);
      if (!resolved) return clip;

      return {
        ...clip,
        variantLabel: clip.variantLabel || resolved.title,
        color: clip.color || resolved.color,
        productGid: clip.productGid || resolved.productGid,
        productId: clip.productId || resolved.productId,
        price: clip.price ?? resolved.price,
        originalPrice: clip.originalPrice ?? resolved.originalPrice,
        thumbUrl: clip.thumbUrl ?? resolved.thumbUrl,
      } as T;
    });
  }

  private async enrichClipsWithProductPrice<
    T extends {
      productId?: number | null;
      productGid?: string | null;
      price?: number | null;
      originalPrice?: number | null;
    }
  >(clips: T[]): Promise<T[]> {
    // Filter clips that need price enrichment (have productId but no price)
    const clipsNeedingPrice = clips.filter(
      (clip) => clip.productId && !clip.price && String(clip.productGid || '').startsWith('gid://shopify/Product/')
    );

    if (clipsNeedingPrice.length === 0) {
      return clips;
    }

    const productGids = Array.from(new Set(clipsNeedingPrice.map((clip) => clip.productGid).filter(Boolean)));

    const queryText = `
      query ResolveProductPrices($ids: [ID!]!) {
        nodes(ids: $ids) {
          ... on Product {
            id
            priceRange {
              minVariantPrice {
                amount
              }
            }
            variants(first: 1) {
              nodes {
                compareAtPrice {
                  amount
                }
              }
            }
          }
        }
      }
    `;

    const response = await this.graphqlRequest<{ nodes: Array<any> }>(queryText, {
      ids: productGids,
    });

    const priceMap = new Map<string, { price: number; originalPrice: number | null }>();

    for (const node of response.nodes || []) {
      if (!node?.id) continue;
      const price = node.priceRange?.minVariantPrice?.amount ? parseFloat(node.priceRange.minVariantPrice.amount) : null;
      const originalPrice = node.variants?.nodes?.[0]?.compareAtPrice?.amount
        ? parseFloat(node.variants.nodes[0].compareAtPrice.amount)
        : null;

      if (price) {
        priceMap.set(String(node.id), { price, originalPrice });
      }
    }

    return clips.map((clip) => {
      // If clip already has price, don't override
      if (clip.price) return clip;

      const productGid = String(clip.productGid || '');
      const priceData = priceMap.get(productGid);

      if (!priceData) return clip;

      return {
        ...clip,
        price: priceData.price,
        originalPrice: clip.originalPrice ?? priceData.originalPrice,
      } as T;
    });
  }

  private parsePotentialProductId(value: string | null): number | null {
    if (!value) return null;

    if (value.includes('gid://shopify/Product/')) {
      return this.parseShopifyId(value);
    }

    const maybeId = Number(value);
    if (Number.isInteger(maybeId) && maybeId > 0) {
      return maybeId;
    }

    return null;
  }

  private parsePotentialProductGid(value: string | null): string | null {
    if (!value) return null;
    if (value.includes('gid://shopify/Product/')) {
      return value;
    }
    return null;
  }

  private parsePotentialVariantGid(value: string | null): string | null {
    if (!value) return null;
    if (value.includes('gid://shopify/ProductVariant/')) {
      return value;
    }
    return null;
  }

  private toNumber(value: string | null): number | null {
    if (!value) return null;
    const parsed = Number(value.replace(',', '.'));
    return Number.isFinite(parsed) ? parsed : null;
  }

  private toBoolean(value: string): boolean {
    const normalized = value.trim().toLowerCase();
    return ['true', '1', 'yes', 'sim', 'active', 'ativo'].includes(normalized);
  }

  private parseShopifyId(gid: string): number {
    const match = /\/(\d+)$/.exec(gid);
    return match ? parseInt(match[1], 10) : 0;
  }
}
