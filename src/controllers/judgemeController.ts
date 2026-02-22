import { Request, Response } from 'express';
import { JudgeMeService } from '../services/judgemeService';

export class JudgeMeController {
  private judgemeService: JudgeMeService;

  constructor() {
    this.judgemeService = new JudgeMeService();
  }

  public async getHomeReviews(req: Request, res: Response): Promise<void> {
    try {
      const count = req.query.count ? parseInt(req.query.count as string) : 6;
      
      const reviews = await this.judgemeService.getHomeReviews(count);
      
      res.json({
        success: true,
        total: reviews.length,
        reviews,
      });
    } catch (error) {
      console.error('Error fetching home reviews:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch reviews',
      });
    }
  }

  public async getProductReviews(req: Request, res: Response): Promise<void> {
    try {
      const { productId } = req.params;
      const page = req.query.page ? parseInt(req.query.page as string) : 1;
      const perPage = req.query.perPage ? parseInt(req.query.perPage as string) : 10;
      
      const result = await this.judgemeService.getProductReviews(productId, { page, perPage });
      
      res.json({
        success: true,
        ...result,
      });
    } catch (error) {
      console.error('Error fetching product reviews:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch product reviews',
      });
    }
  }

  public async getStoreReviews(req: Request, res: Response): Promise<void> {
    try {
      const page = req.query.page ? parseInt(req.query.page as string) : 1;
      const perPage = req.query.perPage ? parseInt(req.query.perPage as string) : 20;
      const minRating = req.query.minRating ? parseInt(req.query.minRating as string) : 4;
      const hasPhotos = req.query.hasPhotos === 'true';
      
      const result = await this.judgemeService.getStoreReviews({
        page,
        perPage,
        minRating,
        hasPhotos,
      });
      
      res.json({
        success: true,
        ...result,
      });
    } catch (error) {
      console.error('Error fetching store reviews:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch store reviews',
      });
    }
  }
}
