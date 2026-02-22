import { Request, Response } from 'express';
import crypto from 'crypto';
import { ShopifyService } from '../services/shopifyService';

export class ShopifyController {
  private shopifyService: ShopifyService;

  constructor() {
    this.shopifyService = new ShopifyService();
  }

  public async getProducts(req: Request, res: Response): Promise<void> {
    try {
      const first = req.query.first ? parseInt(req.query.first as string, 10) : undefined;
      const after = req.query.after ? String(req.query.after) : undefined;
      const query = req.query.query ? String(req.query.query) : undefined;
      const sortKey = req.query.sortKey ? String(req.query.sortKey) : undefined;
      const reverse = req.query.reverse ? String(req.query.reverse) === 'true' : undefined;

      const data = await this.shopifyService.getProducts({ first, after, query, sortKey, reverse });
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching Shopify products', error: String(error) });
    }
  }

  public async getProductById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      if (!id) {
        res.status(400).json({ message: 'Product ID is required' });
        return;
      }

      const data = await this.shopifyService.getProductById(id);
      res.status(200).json(data);
    } catch (error) {
      if (String(error).includes('Product not found')) {
        res.status(404).json({ message: 'Product not found' });
      } else {
        res.status(500).json({ message: 'Error fetching Shopify product', error: String(error) });
      }
    }
  }

  public async getCollections(req: Request, res: Response): Promise<void> {
    try {
      const data = await this.shopifyService.getCollections();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching Shopify collections', error: String(error) });
    }
  }

  public async getStoriesCollections(req: Request, res: Response): Promise<void> {
    try {
      const data = await this.shopifyService.getStoriesCollections();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching Shopify stories collections', error: String(error) });
    }
  }

  public async getProductsByCollection(req: Request, res: Response): Promise<void> {
    try {
      const collectionGid = req.query.collectionGid ? String(req.query.collectionGid) : undefined;
      if (!collectionGid) {
        res.status(400).json({ message: 'collectionGid is required' });
        return;
      }

      const first = req.query.first ? parseInt(req.query.first as string, 10) : undefined;
      const after = req.query.after ? String(req.query.after) : undefined;
      const sortKey = req.query.sortKey ? String(req.query.sortKey) : undefined;
      const reverse = req.query.reverse ? String(req.query.reverse) === 'true' : undefined;

      const data = await this.shopifyService.getProductsByCollection(collectionGid, { first, after, sortKey, reverse });
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching products by collection', error: String(error) });
    }
  }

  public async createCheckout(req: Request, res: Response): Promise<void> {
    try {
      const lines = Array.isArray(req.body?.lines) ? req.body.lines : [];
      if (lines.length === 0) {
        res.status(400).json({ message: 'lines is required' });
        return;
      }

      const data = await this.shopifyService.createCheckout(lines);
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error creating Shopify checkout', error: String(error) });
    }
  }

  public async webhook(req: Request, res: Response): Promise<void> {
    try {
      const secret = process.env.SHOPIFY_WEBHOOK_SECRET || '';
      const provided = req.headers['x-shopify-hmac-sha256'];
      const rawBody = Buffer.isBuffer(req.body) ? req.body : Buffer.from(JSON.stringify(req.body || {}));

      if (secret && provided) {
        const computed = crypto.createHmac('sha256', secret).update(rawBody).digest('base64');
        if (computed !== provided) {
          res.status(401).json({ message: 'Invalid webhook signature' });
          return;
        }
      }

      this.shopifyService.clearCache();
      res.status(200).json({ received: true });
    } catch (error) {
      res.status(500).json({ message: 'Error processing webhook', error: String(error) });
    }
  }

  public async getShopMetafields(req: Request, res: Response): Promise<void> {
    try {
      const data = await this.shopifyService.getShopMetafields();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching shop metafields', error: String(error) });
    }
  }

  public async getClips(req: Request, res: Response): Promise<void> {
    try {
      const referenceListId = req.query.referenceListId
        ? String(req.query.referenceListId)
        : undefined;

      const metaobjectType = req.query.metaobjectType
        ? String(req.query.metaobjectType)
        : undefined;

      const data = await this.shopifyService.getClips(referenceListId, metaobjectType);
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching Shopify clips', error: String(error) });
    }
  }

  public async getProductReviews(req: Request, res: Response): Promise<void> {
    try {
      const productGid = req.query.productGid
        ? String(req.query.productGid)
        : undefined;

      const data = await this.shopifyService.getProductReviews(productGid);
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching product reviews', error: String(error) });
    }
  }
}
