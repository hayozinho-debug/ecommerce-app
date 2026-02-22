import https from 'https';

type JudgeMeConfig = {
  apiToken: string;
  shopDomain: string;
};

type JudgeMeReview = {
  id: number;
  title: string | null;
  body: string;
  rating: number;
  reviewer: {
    name: string;
    email?: string;
  };
  created_at: string;
  verified: string;
  pictures?: Array<{
    urls: {
      original: string;
      small: string;
      compact: string;
      huge: string;
    };
  }>;
  product_external_id?: string;
  product_title?: string;
  product_handle?: string;
};

type JudgeMeResponse = {
  rating: number;
  reviews: JudgeMeReview[];
};

export class JudgeMeService {
  private config: JudgeMeConfig;
  private isConfigured: boolean;

  constructor() {
    const apiToken = process.env.JUDGEME_API_TOKEN || '';
    const shopDomain = process.env.JUDGEME_SHOP_DOMAIN || process.env.SHOPIFY_STORE_DOMAIN || '';

    this.isConfigured = !!(apiToken && shopDomain);
    
    if (!this.isConfigured) {
      console.warn('⚠️  Judge.me API credentials not configured. Using fallback data.');
    }

    this.config = { apiToken, shopDomain };
  }

  public async getReviews(params: {
    shopDomain?: string;
    apiToken?: string;
    perPage?: number;
    page?: number;
    published?: boolean;
    rating?: number;
    hasPhotos?: boolean;
    productId?: string;
    productHandle?: string;
  } = {}) {
    // Return fallback if not configured
    if (!this.isConfigured) {
      return this.getFallbackReviews(params.perPage || 10);
    }

    const {
      shopDomain = this.config.shopDomain,
      apiToken = this.config.apiToken,
      perPage = 10,
      page = 1,
      published = true,
      rating,
      hasPhotos,
      productId,
      productHandle,
    } = params;

    const queryParams = new URLSearchParams({
      api_token: apiToken,
      shop_domain: shopDomain,
      per_page: String(perPage),
      page: String(page),
    });

    if (published !== undefined) {
      queryParams.append('published', published ? 'true' : 'false');
    }

    if (rating !== undefined) {
      queryParams.append('rating', String(rating));
    }

    if (hasPhotos) {
      queryParams.append('has_photos', 'true');
    }

    if (productId) {
      queryParams.append('product_id', productId);
    }

    if (productHandle) {
      queryParams.append('product_handle', productHandle);
    }

    const url = `https://judge.me/api/v1/reviews?${queryParams.toString()}`;

    try {
      const response = await this.fetchWithTimeout(url, 10000);
      const data = JSON.parse(response) as JudgeMeResponse;

      return {
        rating: data.rating || 5,
        total: data.reviews?.length || 0,
        reviews: (data.reviews || []).map(this.normalizeReview),
      };
    } catch (error) {
      console.error('Judge.me API error:', error);
      throw new Error(`Failed to fetch reviews: ${error}`);
    }
  }

  public async getStoreReviews(params: {
    perPage?: number;
    page?: number;
    minRating?: number;
    hasPhotos?: boolean;
  } = {}) {
    const { perPage = 20, page = 1, minRating = 4, hasPhotos = false } = params;

    return this.getReviews({
      perPage,
      page,
      published: true,
      rating: minRating,
      hasPhotos,
    });
  }

  public async getProductReviews(productIdentifier: string | number, params: {
    perPage?: number;
    page?: number;
  } = {}) {
    const { perPage = 10, page = 1 } = params;
    
    const isProductId = typeof productIdentifier === 'number' || /^\d+$/.test(String(productIdentifier));
    
    return this.getReviews({
      perPage,
      page,
      published: true,
      ...(isProductId 
        ? { productId: String(productIdentifier) }
        : { productHandle: String(productIdentifier) }
      ),
    });
  }

  public async getHomeReviews(count: number = 6) {
    // Get reviews with 4+ stars and photos for the home page showcase
    const result = await this.getStoreReviews({
      perPage: count,
      page: 1,
      minRating: 4,
      hasPhotos: false, // Change to true if you want only reviews with photos
    });

    return result.reviews;
  }

  private normalizeReview(review: JudgeMeReview) {
    const pictureUrl = review.pictures?.[0]?.urls?.compact || review.pictures?.[0]?.urls?.small || null;

    return {
      id: review.id,
      name: review.reviewer?.name || 'Cliente',
      rating: review.rating,
      title: review.title || null,
      text: review.body || '',
      imageUrl: pictureUrl || this.getDefaultAvatarUrl(review.reviewer?.name),
      date: this.formatDate(review.created_at),
      verified: review.verified === 'yes',
      productId: review.product_external_id || null,
      productTitle: review.product_title || null,
      productHandle: review.product_handle || null,
    };
  }

  private getDefaultAvatarUrl(name?: string): string {
    // Generate a consistent avatar based on name
    if (!name) return 'https://ui-avatars.com/api/?name=Cliente&background=1054ff&color=fff&size=400';
    
    const cleanName = name.split(' ').slice(0, 2).join('+');
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(cleanName)}&background=1054ff&color=fff&size=400`;
  }

  private formatDate(isoDate: string): string {
    try {
      const date = new Date(isoDate);
      const day = date.getDate();
      const month = date.toLocaleDateString('pt-BR', { month: 'short' });
      const year = date.getFullYear();
      
      return `${day} ${month.charAt(0).toUpperCase() + month.slice(1)} ${year}`;
    } catch {
      return 'Recente';
    }
  }

  private fetchWithTimeout(url: string, timeout: number): Promise<string> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error('Request timeout'));
      }, timeout);

      https.get(url, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          clearTimeout(timer);
          if (res.statusCode === 200) {
            resolve(data);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });

        res.on('error', (err) => {
          clearTimeout(timer);
          reject(err);
        });
      }).on('error', (err) => {
        clearTimeout(timer);
        reject(err);
      });
    });
  }

  private getFallbackReviews(count: number = 6) {
    const fallbackReviews = [
      {
        id: 1,
        name: 'Maria Silva',
        rating: 5,
        title: 'Qualidade excepcional',
        text: 'Produto de excelente qualidade, super recomendo! Tecido muito confortável.',
        imageUrl: 'https://ui-avatars.com/api/?name=Maria+Silva&background=1054ff&color=fff&size=400',
        date: '15 Jan 2025',
        verified: true,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
      {
        id: 2,
        name: 'João Santos',
        rating: 5,
        title: 'Adorei!',
        text: 'Chegou rápido e bem embalado. Superou minhas expectativas!',
        imageUrl: 'https://ui-avatars.com/api/?name=João+Santos&background=1054ff&color=fff&size=400',
        date: '10 Jan 2025',
        verified: true,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
      {
        id: 3,
        name: 'Ana Costa',
        rating: 4,
        title: 'Muito bom',
        text: 'Produto bonito e confortável. Vale a pena!',
        imageUrl: 'https://ui-avatars.com/api/?name=Ana+Costa&background=1054ff&color=fff&size=400',
        date: '5 Jan 2025',
        verified: false,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
      {
        id: 4,
        name: 'Pedro Lima',
        rating: 5,
        title: 'Perfeito',
        text: 'Exatamente como esperava. Qualidade top!',
        imageUrl: 'https://ui-avatars.com/api/?name=Pedro+Lima&background=1054ff&color=fff&size=400',
        date: '28 Dez 2024',
        verified: true,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
      {
        id: 5,
        name: 'Carla Mendes',
        rating: 5,
        title: 'Recomendo',
        text: 'Minha terceira compra, sempre perfeito!',
        imageUrl: 'https://ui-avatars.com/api/?name=Carla+Mendes&background=1054ff&color=fff&size=400',
        date: '20 Dez 2024',
        verified: true,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
      {
        id: 6,
        name: 'Lucas Oliveira',
        rating: 4,
        title: 'Satisfeito',
        text: 'Produto de qualidade, entrega rápida.',
        imageUrl: 'https://ui-avatars.com/api/?name=Lucas+Oliveira&background=1054ff&color=fff&size=400',
        date: '15 Dez 2024',
        verified: false,
        productId: null,
        productTitle: null,
        productHandle: null,
      },
    ];

    return {
      rating: 4.8,
      total: Math.min(count, fallbackReviews.length),
      reviews: fallbackReviews.slice(0, count),
    };
  }
}
